#! /module/for/moderni/sh
\command unalias _Msh_doEndLocal _Msh_doSetLocal _Msh_sL_temp 2>/dev/null
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
#	long-form shell option, or a --split, --glob or --nglob option. Unlike
#	with 'push', variables are unset or assigned, and shell options are set
#	(e.g. -f, -o noglob) or unset (e.g. +f, +o noglob), after pushing their
#	original values/settings onto the stack.
#	    If --split or --*glob options are given, the <arg>s after the -- are
#	subjected to field spitting and/or globbing, without activating field
#	splitting or globbing within the LOCAL block itself. These processed
#	<arg>s then become the positional parameters (PPs) within the LOCAL
#	block. The --split option can have an argument (--split=chars) that
#	are the character(s) to split on, as in IFS.
#	    The --nglob option is like --glob, except words that match 0 files
#	are removed instead of resolving to themselves.
#	    If no <arg>s are given, any --split or --*glob options are ignored
#	and the LOCAL block inherits an unchanged copy of the parent PPs.
#	    Note that the --split and --*glob options do NOT activate field
#	splitting and globbing within the code block itself -- in fact the
#	point of those options is to safely split or glob arguments without
#	affecting any code. Local split and glob can be achieved simply by
#	adding the IFS variable and turning off 'noglob' (+f or +o noglob) like
#	any other <item>.
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

alias LOCAL="{ ${_Msh_sL_ksh93}unset -v _Msh_sL; { _Msh_doSetLocal ${_Msh_sL_LINENO}"
alias BEGIN="}; isset _Msh_sL && _Msh_sL_temp() { eval \"\${_Msh_PPs+unset -v _Msh_PPs; set -- \${_Msh_PPs}}\"; "
alias END="} || die 'LOCAL: init lost'; _Msh_sL_temp \"\$@\"; _Msh_doEndLocal \"\$?\" ${_Msh_sL_LINENO}; }"

unset -v _Msh_sL_LINENO _Msh_sL_ksh93


# Internal functions that do the work. Not for direct use.

_Msh_doSetLocal() {
	not isset _Msh_sL || die "LOCAL: spurious re-init" || return

	# line number for error message if we die (if shell has $LINENO)
	_Msh_sL_LN=$1
	shift

	unset -v _Msh_sL _Msh_sL_o _Msh_sL_splitd _Msh_sL_splitv _Msh_sL_glob

	# Validation; gather arguments for 'push' in ${_Msh_sL}.
	for _Msh_sL_A do
		case ${_Msh_sL_o-} in	# BUG_LOOPISSET compat: don't use ${_Msh_sL_o+s}
		( y )	if not thisshellhas -o "${_Msh_sL_A}"; then
				die "LOCAL${_Msh_sL_LN:+ (line $_Msh_sL_LN)}: no such shell option: -o ${_Msh_sL_A}" || return
			fi
			_Msh_sL="${_Msh_sL+${_Msh_sL} }-o ${_Msh_sL_A}"
			unset -v _Msh_sL_o
			continue ;;
		esac
		case "${_Msh_sL_A}" in
		( -- )	break ;;
		( --split | --split=* | --glob | --nglob )
			continue ;;
		( [-+]o )
			_Msh_sL_o=y	# expect argument
			continue ;;
		( [-+]["$ASCIIALNUM"] )
			if not thisshellhas "-${_Msh_sL_A#?}"; then
				die "LOCAL${_Msh_sL_LN:+ (line $_Msh_sL_LN)}: no such shell option: ${_Msh_sL_A}" || return
			fi
			_Msh_sL_V="-${_Msh_sL_A#[-+]}" ;;
		( *=* )	_Msh_sL_V=${_Msh_sL_A%%=*} ;;
		( * )	_Msh_sL_V=${_Msh_sL_A} ;;
		esac
		case "${_Msh_sL_V}" in
		( -["$ASCIIALNUM"] )	# shell option: ok
			;;
		( '' | [0123456789]* | *[!"$ASCIIALNUM"_]* )
			die "LOCAL${_Msh_sL_LN:+ (line $_Msh_sL_LN)}: invalid variable name or shell option: ${_Msh_sL_V}" \
			|| return ;;
		esac
		_Msh_sL="${_Msh_sL+${_Msh_sL} }${_Msh_sL_V}"
	done
	case ${_Msh_sL_o-} in
	( y )	die "LOCAL${_Msh_sL_LN:+ (line $_Msh_sL_LN)}: ${_Msh_sL_A}: option requires argument" || return ;;
	esac

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
		( -- )	break ;;
		( --split )
			_Msh_sL_splitd=y; unset -v _Msh_sL_splitv ;;
		( --split=* )
			_Msh_sL_splitv=${1#--split=}; unset -v _Msh_sL_splitd ;;
		( --glob )
			_Msh_sL_glob=y ;;
		( --nglob )
			_Msh_sL_glob=N ;;
		( [+-]o )
			command set "$1" "$2" || { _Msh_E="'set $1 $2' failed"; break; }
			shift ;;
		( [-+]["$ASCIIALNUM"] )
			command set "$1" || { _Msh_E="'set $1' failed"; break; } ;;
		( *=* )	eval "${1%%=*}=\${1#*=}" ;;
		( * )	unset -v "$1" ;;
		esac
		shift
	done

	# On an interactive shell, restore global settings when interrupted or die()ing.
	# This restores modernish INT trap handling.
	if isset -i; then
		pushtrap --nosubshell --key=_Msh_setlocal '_Msh_doEndLocal int' INT
	fi

	if isset _Msh_E; then
		die "LOCAL${_Msh_sL_LN:+ (line $_Msh_sL_LN)}: ${_Msh_E}" || return
	fi

	# If there are are arguments left, make them the positional parameters of the LOCAL block.
	# First, if specified, subject them to field splitting and/or pathname expansion (globbing).
	# Then store them shellquoted in _Msh_PPs for later eval'ing in the temp function.
	unset -v _Msh_PPs
	if let "$#"; then
		shift		# remove '--'
		push IFS -f
		case ${_Msh_sL_splitv+v}${_Msh_sL_splitd+d} in
		( v )	IFS=${_Msh_sL_splitv} ;;
		( d )	unset -v IFS ;;		# shell default split
		( '' )	IFS='' ;;		# by default, don't split
		( * )	die "LOCAL${_Msh_sL_LN:+ (line $_Msh_sL_LN)}: internal error" || return ;;
		esac
		case ${_Msh_sL_glob+g} in
		( g )	set +f ;;
		( '' )	set -f ;;
		esac
		for _Msh_sL_A do
			case ${_Msh_sL_A} in
			( '' )	set -- '' ;;		# preserve empties
			( * )	set -- ${_Msh_sL_A}	# do split and/or glob, if set
			esac
			for _Msh_sL_A do
				case ${_Msh_sL_glob-} in
				( N )	is present "${_Msh_sL_A}" || continue ;;
				esac
				shellquote _Msh_sL_A
				_Msh_PPs=${_Msh_PPs:+${_Msh_PPs} }${_Msh_sL_A}
			done
		done
		pop IFS -f
	else
		case ${_Msh_sL_splitv+v}${_Msh_sL_splitd+d} in
		( ?* )	die "LOCAL${_Msh_sL_LN:+ (line $_Msh_sL_LN)}: --split or --glob require words to operate on" || return ;;
		esac
	fi

	unset -v _Msh_sL_V _Msh_sL_A _Msh_sL_o _Msh_sL_LN _Msh_sL_splitd _Msh_sL_splitv _Msh_sL_glob
	_Msh_sL=y
	return 1	# on the first call, don't execute the block
}

_Msh_doEndLocal() {
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
