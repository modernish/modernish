#! /module/for/moderni/sh
\command unalias BEGIN END LOCAL _Msh_sL_END _Msh_sL_LOCAL _Msh_sL_die _Msh_sL_genPPs_base _Msh_sL_reallyunsetIFS _Msh_sL_setPPs _Msh_sL_temp 2>/dev/null
#
# modernish var/local
#
# A triplet of aliases for a LOCAL...BEGIN...END code block. Local variables
# and local shell options are supported, with those specified becoming local
# and the rest remaining global. The exit status of the block is the exit
# status of the last command. Positional parameters are passed into the
# block but changes are lost when exiting from it. Use 'return' (not
# 'break') to safely break out from the block and automatically restore the
# global state. (That's because, internally, the block is a temporary shell
# function.)
#
# Usage:
# LOCAL [ <item> [ <item> ... ] ] [ -- <arg> [ <arg> ... ] ]; BEGIN
#    <command> [ <command> ... ]
# END
#	where <item> is a variable name, variable assignment, short- or
#	long-form shell option, or a --split, --glob or --fglob option. Unlike
#	with 'push', variables are unset or assigned, and shell options are set
#	(e.g. -f, -o noglob) or unset (e.g. +f, +o noglob), after pushing their
#	original values/settings onto the stack.
#	    If --split or --*glob options are given, the <arg>s after the -- are
#	subjected to field spitting and/or globbing, without activating field
#	splitting or globbing within the LOCAL block itself. These processed
#	<arg>s then become the positional parameters (PPs) within the LOCAL
#	block. The --split option can have an argument (--split=chars) that
#	are the character(s) to split on, as in IFS.
#	    The --fglob option is like --glob, except a non-matching pattern is
#	a fatal error, whereas --glob removes non-matching pattern. Note that
#	the default global pathname expansion behaviour, in which unmatched
#	patterns remain unexpanded, is not offered, as this makes no sense when
#	expanding a list of words only.
#	    If no <arg>s are given, any --split or --*glob options are ignored
#	and the LOCAL block inherits an unchanged copy of the parent PPs.
#	    Note that the --split and --*glob options do NOT activate field
#	splitting and pathname expansion within the code block itself -- in
#	fact the point of those options is to safely expand arguments without
#	affecting any code. "Local global" field splitting and pathname
#	expansion for the code block can be achieved simply by adding the IFS
#	variable and turning off 'noglob' (+f or +o noglob) like any other
#	<item>.
#
# Nesting LOCAL...BEGIN...END blocks also works; redefining the temporary
# function while another instance of it is running is not a problem because
# shells create an internal working copy of a function before executing it.
#
# WARNING: To avoid data corruption, never use 'continue' or 'break' within
# BEGIN...END unless the *entire* loop is within the LOCAL block!
# A few shells (ksh, mksh) disallow this because they don't allow 'break' to
# interrupt the temporary shell function, but on others this will silently
# result in stack corruption and non-restoration of global variables and
# shell options. There is no way to block this. POSIX technically allows this
# behaviour. Modernish identifies this flaw as QRK_BCDANGER.
#
# TODO: support local traps.
#
# --- begin license ---
# Copyright (c) 2018 Martijn Dekker <martijn@inlv.org>, Groningen, Netherlands
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# --- end license ---

isset -i && use var/stack/trap

# The aliases below pass $LINENO on to the handling functions for use in error messages, so they can report
# the line number of the 'LOCAL' or 'END' where the error occurred. But on shells with BUG_LNNOALIAS
# (pdksh, mksh) this is pointless as the number is always zero when $LINENO is expanded from an alias.
# And on shells with BUG_LNNONEG (dash), the results would often be wildly inaccurate.
if not thisshellhas LINENO || thisshellhas BUG_LNNOALIAS || thisshellhas BUG_LNNONEG; then
	_Msh_sL_LINENO="''"
else
	_Msh_sL_LINENO='"${LINENO-}"'
fi

# ksh93: Due to BUG_FNSUBSH, this shell cannot unset or redefine a function within a non-forked subshell.
# 'unset -f' and function redefinitions in non-forked subshells are silently ignored without error, and the
# wrong code, i.e. that from the main shell, is re-executed! Thankfully, there are tricks to force the
# current subshell to fork: invoking the 'ulimit' builtin is one of them.
# Ref.:	https://github.com/att/ast/issues/480#issuecomment-384297783
#	https://github.com/att/ast/issues/73#issuecomment-384522134
if thisshellhas BUG_FNSUBSH; then
	_Msh_sL_ksh93='command ulimit -t unlimited 2>/dev/null; '
else
	_Msh_sL_ksh93=''
fi

# Determine how to set expanded positional parameters in the temp function.
# See _Msh_sL_setPPs() function below.
if thisshellhas KSHARRAY; then
	_Msh_sL_setPPs='eval ${_Msh_PPs+"set --"} ${_Msh_PPv+'\''"${_Msh_PPv[@]}"'\''} ${_Msh_PPs+"; unset -v _Msh_PPs _Msh_PPv"}'
else
	_Msh_sL_setPPs='eval ${_Msh_PPs+"set -- ${_Msh_PPs}; unset -v _Msh_PPs _Msh_PPv ${_Msh_PPv}"}'
fi

# The triplet of aliases.

alias LOCAL="{ ${_Msh_sL_ksh93}unset -v _Msh_sL; { _Msh_sL_LOCAL ${_Msh_sL_LINENO}"
alias BEGIN="}; isset _Msh_sL && _Msh_sL_temp() { ${_Msh_sL_setPPs}; "
alias END="} || die 'LOCAL: init lost'; _Msh_sL_temp \"\$@\"; _Msh_sL_END \"\$?\" ${_Msh_sL_LINENO}; }"

unset -v _Msh_sL_LINENO _Msh_sL_ksh93 _Msh_sL_setPPs


# Internal functions that do the work. Not for direct use.

_Msh_sL_LOCAL() {
	not isset _Msh_sL || _Msh_sL_die "spurious re-init"
	isset -i && not insubshell && _Msh_sL_interact=y || unset -v _Msh_sL_interact

	# line number for error message if we die (if shell has $LINENO)
	_Msh_sL_LN=$1
	shift

	unset -v _Msh_sL _Msh_sL_A _Msh_sL_o _Msh_sL_split _Msh_sL_glob _Msh_sL_slice _Msh_sL_base

	# Validation; gather arguments for 'push' in ${_Msh_sL}.
	for _Msh_sL_A do
		case ${_Msh_sL_o-} in	# BUG_LOOPISSET compat: don't use ${_Msh_sL_o+s}
		( y )	if not thisshellhas -o "${_Msh_sL_A}"; then
				_Msh_sL_die "no such shell option: -o ${_Msh_sL_A}"
			fi
			_Msh_sL="${_Msh_sL+${_Msh_sL} }-o ${_Msh_sL_A}"
			unset -v _Msh_sL_o
			continue ;;
		esac
		case "${_Msh_sL_A}" in
		( -- )		break ;;
		( --split )	_Msh_sL_split= ; continue ;;
		( --split= )	unset -v _Msh_sL_split; continue ;;
		( --split=* )	_Msh_sL_split=${_Msh_sL_A#--split=}; continue ;;
		( --glob )	_Msh_sL_glob= ; continue ;;
		( --fglob )	_Msh_sL_glob=f; continue ;;
		( --base )	_Msh_sL_die "option requires argument: ${_Msh_sL_A}" ;;
		( --base=* )	_Msh_sL_base=${_Msh_sL_A#--base=}; continue ;;
		( --slice )	_Msh_sL_slice=1; continue ;;
		( --slice=* )	_Msh_sL_slice=${_Msh_sL_A#--slice=}; continue ;;
		( [-+]o )	_Msh_sL_o=y; continue ;;  # expect argument
		( [-+]["$ASCIIALNUM"] )
				thisshellhas "-${_Msh_sL_A#?}" || _Msh_sL_die "no such shell option: ${_Msh_sL_A}"
				_Msh_sL_V="-${_Msh_sL_A#[-+]}" ;;
		( *=* )		_Msh_sL_V=${_Msh_sL_A%%=*} ;;
		( * )		_Msh_sL_V=${_Msh_sL_A} ;;
		esac
		case "${_Msh_sL_V}" in
		( -["$ASCIIALNUM"] )	# shell option: ok
			;;
		( '' | [0123456789]* | *[!"$ASCIIALNUM"_]* )
			_Msh_sL_die "invalid variable name, shell option or operator: ${_Msh_sL_V}" ;;
		esac
		_Msh_sL="${_Msh_sL+${_Msh_sL} }${_Msh_sL_V}"
	done
	case ${_Msh_sL_o-} in
	( y )	_Msh_sL_die "${_Msh_sL_A}: option requires argument" ;;
	esac
	case ${_Msh_sL_A-} in
	( -- )	;;
	( * )	case ${_Msh_sL_split+s}${_Msh_sL_glob+g} in
		( ?* )	_Msh_sL_die "--split or --*glob require '--'" ;;
		esac ;;
	esac
	if not isset -f || not isset IFS || not str empty "$IFS"; then
		isset _Msh_sL_split && isset _Msh_sL_glob && _Msh_sL_die "--split & --${_Msh_sL_glob}glob without safe mode"
		isset _Msh_sL_split && _Msh_sL_die "--split without safe mode"
		isset _Msh_sL_glob && _Msh_sL_die "--${_Msh_sL_glob}glob without safe mode"
	fi
	if isset _Msh_sL_base && isset _Msh_sL_glob; then
		not str end ${_Msh_sL_base} '/' && _Msh_sL_base=${_Msh_sL_base}/
	fi
	if isset _Msh_sL_slice; then
		if not str isint ${_Msh_sL_slice} || let "_Msh_sL_slice <= 0"; then
			_Msh_sL_die "--slice: invalid number of characters: ${_Msh_sL_slice}"
		fi
		_Msh_sL_pat=''
		while let "${#_Msh_sL_pat} < _Msh_sL_slice"; do
			_Msh_sL_pat=${_Msh_sL_pat}\?
		done
	fi

	# Push the global values/settings onto the stack.
	# (Since our input is now safely validated, abuse 'eval' for
	# field splitting so we don't have to bother with $IFS.)
	eval "push --key=_Msh_setlocal ${_Msh_sL-} _Msh_sL"

	# On an interactive shell, disallow interrupting the following to avoid corruption:
	# ignore SIGINT, temporarily bypassing/disabling modernish trap handling.
	if isset _Msh_sL_interact; then
		command trap '' INT
	fi

	# Apply local values/settings.
	unset -v _Msh_E _Msh_PPs _Msh_PPv
	while	case ${1-} in
		( '' )		break ;;
		( -- )		_Msh_PPs=''
				shift
				break ;;
		( --* )		;;
		( [+-]o )	command set "$1" "$2" || _Msh_E="${_Msh_E:+$_Msh_E; }'set $1 $2' failed"
				shift ;;
		( [-+]["$ASCIIALNUM"] )
				command set "$1" || _Msh_E="${_Msh_E:+$_Msh_E; }'set $1' failed" ;;
		( *=* )		eval "${1%%=*}=\${1#*=}" ;;
		( * )		unset -v "$1" ;;
		esac
	do
		shift
	done

	# On an interactive shell, restore global settings when interrupted or die()ing.
	# This restores modernish INT trap handling.
	if isset _Msh_sL_interact; then
		pushtrap --nosubshell --key=_Msh_setlocal '_Msh_sL_END int' INT
	fi

	# With SIGINT handling in place, now we can die if there were errors.
	if isset _Msh_E; then
		_Msh_sL_die "${_Msh_E}"
	fi

	# If there was a '--', expand the remaining arguments into the positional parameters of the LOCAL block.
	if isset _Msh_PPs; then
		push --key=_Msh_setlocal IFS -f -a
		IFS=''
		set -f +a
		_Msh_sL_setPPs "$@"
		pop --key=_Msh_setlocal IFS -f -a
	fi

	unset -v _Msh_sL_split _Msh_sL_glob _Msh_sL_slice \
		_Msh_sL_pat _Msh_sL_rest \
		_Msh_sL_V _Msh_sL_A _Msh_sL_AA _Msh_sL_o _Msh_sL_i _Msh_sL_LN
	_Msh_sL=y
}

if thisshellhas KSHARRAY; then
	# Version using an array to transfer the PPs with better performance.
	_Msh_sL_setPPs() {
		_Msh_sL_i=-1
		for _Msh_sL_A do
			case ${_Msh_sL_glob+s} in
			( s )	set +f ;;
			esac
			case ${_Msh_sL_glob+G}${_Msh_sL_base+B} in
			( GB )	_Msh_sL_expArgs=$(_Msh_sL_genPPs_base "$@") \
				|| case $? in
				( 100 )	_Msh_sL_die "could not enter base dir: ${_Msh_sL_base}" ;;
				( * )	_Msh_sL_die "internal error" ;;
				esac
				eval "set -- ${_Msh_sL_expArgs}"
				unset -v _Msh_sL_expArgs ;;
			( * )	case ${_Msh_sL_split+s},${_Msh_sL_split-} in
				( s, )	_Msh_sL_reallyunsetIFS ;;  # default split
				( s,* )	IFS=${_Msh_sL_split} ;;
				esac
				# Do the expansion.
				set -- ${_Msh_sL_A}
				# BUG_IFSGLOBC, BUG_IFSCC01PP compat: immediately empty IFS again, as
				# some values of IFS break 'case' or "$@" and hence all of modernish.
				IFS=''
				set -f ;;
			esac
			# Store expansion results in _Msh_PPv[] for the BEGIN alias.
			# Modify glob results for safety.
			for _Msh_sL_AA do
				case ${_Msh_sL_base+B} in
				( B )	_Msh_sL_AA=${_Msh_sL_base}${_Msh_sL_AA} ;;
				esac
				case ${_Msh_sL_glob-NO} in
				( '' )	is present "${_Msh_sL_AA}" || continue ;;
				( f )	is present "${_Msh_sL_AA}" || _Msh_sL_die "--fglob: no match: ${_Msh_sL_AA}" ;;
				esac
				case ${_Msh_sL_glob+G},${_Msh_sL_AA} in
				( G,-* | G,+* | G,\( | G,\! )
					# Avoid accidental parsing as option/operand in various commands.
					_Msh_sL_AA=./${_Msh_sL_AA} ;;
				esac
				case ${_Msh_sL_slice+S} in
				( S )	while let "${#_Msh_sL_AA} > _Msh_sL_slice"; do
						_Msh_sL_rest=${_Msh_sL_AA#$_Msh_sL_pat}
						_Msh_PPv[$(( _Msh_sL_i += 1 ))]=${_Msh_sL_AA%"$_Msh_sL_rest"}
						_Msh_sL_AA=${_Msh_sL_rest}
					done ;;
				esac
				_Msh_PPv[$(( _Msh_sL_i += 1 ))]=${_Msh_sL_AA}
			done
			if let "$# == 0" && not str empty "${_Msh_sL_glob-NO}"; then
				# Preserve empties. (The shell did its empty removal thing before
				# invoking LOCAL, so any empties left must have been quoted.)
				str eq "${_Msh_sL_glob-NO}" f && _Msh_sL_die "--fglob: empty pattern"
				_Msh_PPv[$(( _Msh_sL_i += 1 ))]=''
			fi
		done
		case ${_Msh_PPv+s},${_Msh_sL_glob-} in
		( ,f )	_Msh_sL_die "--fglob: no patterns"
		esac
	}
else
	# Version for shells without arrays.
	_Msh_sL_setPPs() {
		_Msh_PPv=''
		_Msh_sL_i=0
		for _Msh_sL_A do
			case ${_Msh_sL_glob+s} in
			( s )	set +f ;;
			esac
			case ${_Msh_sL_glob+G}${_Msh_sL_base+B} in
			( GB )	_Msh_sL_expArgs=$(_Msh_sL_genPPs_base "$@") \
				|| case $? in
				( 100 )	_Msh_sL_die "could not enter base dir: ${_Msh_sL_base}" ;;
				( * )	_Msh_sL_die "internal error" ;;
				esac
				eval "set -- ${_Msh_sL_expArgs}"
				unset -v _Msh_sL_expArgs ;;
			( * )	case ${_Msh_sL_split+s},${_Msh_sL_split-} in
				( s, )	_Msh_sL_reallyunsetIFS ;;  # default split
				( s,* )	IFS=${_Msh_sL_split} ;;
				esac
				# Do the expansion.
				set -- ${_Msh_sL_A}
				# BUG_IFSGLOBC, BUG_IFSCC01PP compat: immediately empty IFS again, as
				# some values of IFS break 'case' or "$@" and hence all of modernish.
				IFS=''
				set -f ;;
			esac
			# Store expansion results in _Msh_1, _Msh_2, ... for the BEGIN alias.
			# Modify glob results for safety.
			for _Msh_sL_AA do
				case ${_Msh_sL_base+B} in
				( B )	_Msh_sL_AA=${_Msh_sL_base}${_Msh_sL_AA} ;;
				esac
				case ${_Msh_sL_glob-NO} in
				( '' )	is present "${_Msh_sL_AA}" || continue ;;
				( f )	is present "${_Msh_sL_AA}" || _Msh_sL_die "--fglob: no match: ${_Msh_sL_AA}" ;;
				esac
				case ${_Msh_sL_glob+G},${_Msh_sL_AA} in
				( G,-* | G,+* | G,\( | G,\! )
					# Avoid accidental parsing as option/operand in various commands.
					_Msh_sL_AA=./${_Msh_sL_AA} ;;
				esac
				case ${_Msh_sL_slice+S} in
				( S )	while let "${#_Msh_sL_AA} > _Msh_sL_slice"; do
						_Msh_sL_rest=${_Msh_sL_AA#$_Msh_sL_pat}
						eval "_Msh_$(( _Msh_sL_i += 1 ))=\${_Msh_sL_AA%\"\${_Msh_sL_rest}\"}"
						_Msh_PPs="${_Msh_PPs} \"\$_Msh_${_Msh_sL_i}\""
						_Msh_PPv="${_Msh_PPv} _Msh_${_Msh_sL_i}"
						_Msh_sL_AA=${_Msh_sL_rest}
					done ;;
				esac
				eval "_Msh_$(( _Msh_sL_i += 1 ))=\${_Msh_sL_AA}"
				_Msh_PPs="${_Msh_PPs} \"\$_Msh_${_Msh_sL_i}\""
				_Msh_PPv="${_Msh_PPv} _Msh_${_Msh_sL_i}"
			done
			if let "$# == 0" && not str empty "${_Msh_sL_glob-NO}"; then
				# Preserve empties. (The shell did its empty removal thing before
				# invoking LOCAL, so any empties left must have been quoted.)
				str eq "${_Msh_sL_glob-NO}" f && _Msh_sL_die "--fglob: empty pattern"
				_Msh_PPs="${_Msh_PPs} ''"
			fi
		done
		case ${_Msh_PPs},${_Msh_sL_glob-} in
		( ,f )	_Msh_sL_die "--fglob: no patterns"
		esac
	}
fi

# Internal function for --*glob with --base. Called from a command substitution subshell.
# We have to chdir in order to do the expansion correctly, especially if --split is also given. Changing the
# working directory is only safe (no race condition involving restoring it) if we do this within a subshell.
_Msh_sL_genPPs_base() {
	thisshellhas BUG_FNSUBSH && command ulimit -t unlimited 2>/dev/null  # fork on ksh93; see https://github.com/att/ast/issues/480
	case ${_Msh_sL_glob} in
	( f )	chdir -f -- "${_Msh_sL_base}" || exit 100 ;;
	( * )	chdir -f -- "${_Msh_sL_base}" 2>/dev/null || exit 0 ;;
	esac
	case ${_Msh_sL_split+s},${_Msh_sL_split-} in
	( s, )	while isset IFS; do unset -v IFS; done ;;  # default split, QRK_LOCALUNS/QRK_LOCALUNS2 compat
	( s,* )	IFS=${_Msh_sL_split} ;;
	esac
	# Do the expansion.
	set -- ${_Msh_sL_A}
	# BUG_IFSGLOBC, BUG_IFSCC01PP compat: immediately empty IFS again, as
	# some values of IFS break 'case' or "$@" and hence all of modernish.
	IFS=''
	use var/shellquote
	for _Msh_sL_A do
		shellquote _Msh_sL_A
		put " ${_Msh_sL_A}"
	done
}

_Msh_sL_die() {
	# Die with line number in error message, if available.
	pop --key=_Msh_setlocal IFS -f -a  # if pushed
	die "LOCAL${_Msh_sL_LN:+ (line $_Msh_sL_LN)}: $@"
}

_Msh_sL_END() {
	# Unsetting the temp function makes ksh93 "AJM 93u+ 2012-08-01", the
	# latest release version as of 2019, segfault if LOCAL...BEGIN...END
	# blocks are nested.
	# So we don't do this:
	#unset -f _Msh_sL_temp

	case $1 in
	( int )	unset -v _Msh_sL_interact; set 0 ;;
	( * )	if isset _Msh_sL_interact; then
			unset -v _Msh_sL_interact _Msh_sL_save
			while poptrap -R INT; do
				# save keyless INT traps pushed inside LOCAL
				_Msh_sL_save=${_Msh_sL_save-}${REPLY}${CCn}
			done
			poptrap --key=_Msh_setlocal INT || {
				eval "${_Msh_sL_save-}"
				unset -v _Msh_sL_save
				die "END${2:+ (line $2)}: stack corrupted (failed to pop INT trap)"
			}
			eval "${_Msh_sL_save-}"	# re-push traps
			unset -v _Msh_sL_save
		fi ;;
	esac

	pop --key=_Msh_setlocal _Msh_sL \
	|| die "END${2:+ (line $2)}: stack corrupted (failed to pop arguments)"
	if isset _Msh_sL; then
		eval "pop --key=_Msh_setlocal ${_Msh_sL}" \
		|| die "END${2:+ (line $2)}: stack corrupted (failed to pop globals)"
		unset -v _Msh_sL
	fi
	return "$1"
}

# Verify that 'unset -v IFS' works and does not expose a parent local or global scope. If it fails,
# we must die(), because LOCAL is executed in the main shell environment; therefore, simply trying
# again until it is unset (as in var/loop _loop_reallyunsetIFS()) would cause an inconsistent state.
_Msh_sL_reallyunsetIFS() {
	unset -v IFS
	if isset -v IFS; then
		_Msh_sL_msg="LOCAL --split: unsetting IFS failed"
		thisshellhas QRK_LOCALUNS && _Msh_sL_msg="${_Msh_sL_msg} (QRK_LOCALUNS)"
		thisshellhas QRK_LOCALUNS2 && _Msh_sL_msg="${_Msh_sL_msg} (QRK_LOCALUNS2)"
		die "${_Msh_sL_msg}"
	fi
}

if thisshellhas ROFUNC; then
	readonly -f _Msh_sL_END _Msh_sL_LOCAL _Msh_sL_die _Msh_sL_genPPs_base _Msh_sL_reallyunsetIFS _Msh_sL_setPPs
fi
