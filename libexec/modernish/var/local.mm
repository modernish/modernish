#! /module/for/moderni/sh
\command unalias _Msh_sL_END _Msh_sL_LOCAL _Msh_sL_die _Msh_sL_temp 2>/dev/null
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
if not thisshellhas LINENO || thisshellhas BUG_LNNOALIAS; then
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

# The triplet of aliases.

alias LOCAL="{ ${_Msh_sL_ksh93}unset -v _Msh_sL; { _Msh_sL_LOCAL ${_Msh_sL_LINENO}"
alias BEGIN="}; isset _Msh_sL && _Msh_sL_temp() { eval \"\${_Msh_PPs+unset -v _Msh_PPs; set -- \${_Msh_PPs}}\"; "
alias END="} || die 'LOCAL: init lost'; _Msh_sL_temp \"\$@\"; _Msh_sL_END \"\$?\" ${_Msh_sL_LINENO}; }"

unset -v _Msh_sL_LINENO _Msh_sL_ksh93


# Internal functions that do the work. Not for direct use.

_Msh_sL_LOCAL() {
	not isset _Msh_sL || _Msh_sL_die "spurious re-init" || return

	# line number for error message if we die (if shell has $LINENO)
	_Msh_sL_LN=$1
	shift

	unset -v _Msh_sL _Msh_sL_o _Msh_sL_split _Msh_sL_glob

	# Validation; gather arguments for 'push' in ${_Msh_sL}.
	for _Msh_sL_A do
		case ${_Msh_sL_o-} in	# BUG_LOOPISSET compat: don't use ${_Msh_sL_o+s}
		( y )	if not thisshellhas -o "${_Msh_sL_A}"; then
				_Msh_sL_die "no such shell option: -o ${_Msh_sL_A}" || return
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
		( [-+]o )	_Msh_sL_o=y; continue ;;  # expect argument
		( [-+]["$ASCIIALNUM"] )
				thisshellhas "-${_Msh_sL_A#?}" || _Msh_sL_die "no such shell option: ${_Msh_sL_A}" || return
				_Msh_sL_V="-${_Msh_sL_A#[-+]}" ;;
		( *=* )		_Msh_sL_V=${_Msh_sL_A%%=*} ;;
		( * )		_Msh_sL_V=${_Msh_sL_A} ;;
		esac
		case "${_Msh_sL_V}" in
		( -["$ASCIIALNUM"] )	# shell option: ok
			;;
		( '' | [0123456789]* | *[!"$ASCIIALNUM"_]* )
			_Msh_sL_die "invalid variable name, shell option or operator: ${_Msh_sL_V}" \
			|| return ;;
		esac
		_Msh_sL="${_Msh_sL+${_Msh_sL} }${_Msh_sL_V}"
	done
	case ${_Msh_sL_o-} in
	( y )	_Msh_sL_die "${_Msh_sL_A}: option requires argument" || return ;;
	esac
	if not isset -f || not isset IFS || not empty "$IFS"; then
		isset _Msh_sL_split && isset _Msh_sL_glob && _Msh_sL_die "--split & --${_Msh_sL_glob}glob without safe mode"
		isset _Msh_sL_split && _Msh_sL_die "--split without safe mode"
		isset _Msh_sL_glob && _Msh_sL_die "--${_Msh_sL_glob}glob without safe mode"
	fi

	# Push the global values/settings onto the stack.
	# (Since our input is now safely validated, abuse 'eval' for
	# field splitting so we don't have to bother with $IFS.)
	eval "push --key=_Msh_setlocal ${_Msh_sL-} _Msh_sL" || return

	# On an interactive shell, disallow interrupting the following to avoid corruption:
	# ignore SIGINT, temporarily bypassing/disabling modernish trap handling.
	if isset -i; then
		command trap '' INT
	fi

	# Apply local values/settings.
	unset -v _Msh_E
	while let "$#"; do
		case $1 in
		( -- )		break ;;
		( --split | --split=* | --glob | --fglob )
				;;
		( [+-]o )	command set "$1" "$2" || _Msh_E="${_Msh_E:+$_Msh_E; }'set $1 $2' failed"
				shift ;;
		( [-+]["$ASCIIALNUM"] )
				command set "$1" || _Msh_E="${_Msh_E:+$_Msh_E; }'set $1' failed" ;;
		( *=* )		eval "${1%%=*}=\${1#*=}" ;;
		( * )		unset -v "$1" ;;
		esac
		shift
	done

	# On an interactive shell, restore global settings when interrupted or die()ing.
	# This restores modernish INT trap handling.
	if isset -i; then
		pushtrap --nosubshell --key=_Msh_setlocal '_Msh_sL_END int' INT
	fi

	# With SIGINT handling in place, now we can die if there were errors.
	if isset _Msh_E; then
		_Msh_sL_die "${_Msh_E}" || return
	fi

	# If there are are arguments left, make them the positional parameters of the LOCAL block.
	# First, if specified, subject them to field splitting and/or pathname expansion (globbing).
	# Then store them shellquoted in _Msh_PPs for later eval'ing in the temp function.
	unset -v _Msh_PPs
	if let "$# > 1"; then
		shift		# remove '--'
		push IFS -f
		if isset _Msh_sL_split; then
			if empty "${_Msh_sL_split}"; then
				# Unset IFS to get default fieldsplitting.
				while isset IFS; do unset -v IFS; done	# QRK_LOCALUNS/QRK_LOCALUNS2 compat
			else
			#	# BUG_IFSCC01PP/BUG_IFSGLOBC/BUG_IFSGLOBP/BUG_IFSGLOBS compat:
			#	# Split characters could be given that break modernish, so delay this:
			#	IFS=${_Msh_sL_split}
				IFS=''
			fi
		else
			IFS=''
		fi
		if isset _Msh_sL_glob; then
			set +f
		else
			set -f
		fi
		# If split and/or glob are now globally active, any unquoted expansions will apply
		# them -- except within 'case'...'in', in 'case' patterns, and shell assignments.
		for _Msh_sL_A do
			unset -v _Msh_sL_AA
			not empty "${_Msh_sL_split-}" && IFS=${_Msh_sL_split}	# BUG_IFS* compat: delayed as per above
			for _Msh_sL_AA in ${_Msh_sL_A}; do
			#		  ^^^^^^^^^^^^ This unquoted expansion does the splitting and/or globbing.
				IFS=''						# BUG_IFS* compat: unbreak modernish
				case ${_Msh_sL_glob-NO} in
				( '' )	is present "${_Msh_sL_AA}" || continue ;;
				( f )	if not is present "${_Msh_sL_AA}"; then
						pop IFS -f
						shellquote -f _Msh_sL_AA
						_Msh_sL_die "--fglob: no match: ${_Msh_sL_AA}" || return
					fi ;;
				esac
				case ${_Msh_sL_glob+G},${_Msh_sL_AA} in
				(G,-*)	# Expanded path starts with '-': avoid accidental parsing as option.
					_Msh_sL_AA=./${_Msh_sL_AA} ;;
				esac
				shellquote _Msh_sL_AA
				_Msh_PPs=${_Msh_PPs:+${_Msh_PPs} }${_Msh_sL_AA}
			done
			if not isset _Msh_sL_AA && not identic "${_Msh_sL_glob-NO}" ''; then
				# Preserve empties. (The shell did its empty removal thing before
				# invoking the loop, so any empties left must have been quoted.)
				identic "${_Msh_sL_glob-NO}" f && { _Msh_sL_die "--fglob: empty pattern" || return; }
				_Msh_PPs=${_Msh_PPs:+${_Msh_PPs} }\'\'
			fi
		done
		pop IFS -f
		case ${_Msh_PPs-},${_Msh_sL_glob-NO} in
		( ,f )	_Msh_sL_die "--fglob: no patterns"
		esac
	elif let "$# == 0"; then
		case ${_Msh_sL_split+s}${_Msh_sL_glob+g} in
		( ?* )	_Msh_sL_die "--split or --*glob require '--'" || return ;;
		esac
	fi

	unset -v _Msh_sL_V _Msh_sL_A _Msh_sL_o _Msh_sL_LN _Msh_sL_split _Msh_sL_glob
	_Msh_sL=y
}

_Msh_sL_die() {
	# Die with line number in error message, if available.
	die "LOCAL${_Msh_sL_LN:+ (line $_Msh_sL_LN)}: $@"
}

_Msh_sL_END() {
	# Unsetting the temp function makes ksh93 "AJM 93u+ 2012-08-01", the
	# latest release version as of 2018, segfault if LOCAL...BEGIN...END
	# blocks are nested.
	# So we don't do this:
	#unset -f _Msh_sL_temp

	case $1 in
	( int )	set 0 ;;
	( * )	if isset -i; then
			unset -v _Msh_sL_save
			while poptrap INT; do
				# save keyless INT traps pushed inside LOCAL
				_Msh_sL_save=${_Msh_sL_save-}${REPLY}${CCn}
			done
			poptrap --key=_Msh_setlocal INT || { eval "${_Msh_sL_save-}"; unset -v _Msh_sL_save; return; }
			eval "${_Msh_sL_save-}"	# re-push traps
			unset -v _Msh_sL_save
		fi ;;
	esac

	pop --key=_Msh_setlocal _Msh_sL \
	|| die "END${2:+ (line $2)}: stack corrupted (failed to pop arguments)" || return
	if isset _Msh_sL; then
		eval "pop --key=_Msh_setlocal ${_Msh_sL}" \
		|| die "END${2:+ (line $2)}: stack corrupted (failed to pop globals)" || return
		unset -v _Msh_sL
	fi
	return "$1"
}

if thisshellhas ROFUNC; then
	readonly -f _Msh_sL_END _Msh_sL_LOCAL _Msh_sL_die
fi
