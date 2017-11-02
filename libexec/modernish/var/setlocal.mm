#! /module/for/moderni/sh
# --- setlocal...endlocal ---
# A pair of aliases for a setlocal ... endlocal code block. Local variables
# and local shell options are supported, with those specified becoming local
# and the rest remaining global. The exit status of the block is the exit
# status of the last command. Positional parameters are passed into the
# block but changes are lost when exiting from it. Use 'return' (not
# 'break') to safely break out from the block and automatically restore the
# global state. (That's because, internally, the block is a temporary shell
# function.)
#
# ksh93 (AT&T ksh) compatibility note:
# Unfortunately, on AT&T ksh, we have to put up with BUG_FNSUBSH breakage. That
# is, if a script is to be compatible with AT&T ksh, setlocal/endlocal cannot
# be used within non-forked subshells, because unsetting/redefining the
# temporary function is impossible. The program would silently execute the
# WRONG code if not for a test implemented below that checks if unsetting
# a dummy function defined in the main shell succeeds. If the function
# cannot be redefined, modernish kills the program rather than allowing the
# shell to execute the wrong code.
# Note that background subshells are forked and this does not apply there.
# Command substitution is also forked if output redirection occurs within
# it; modernish adds a dummy output redirection to the alias, which makes it
# possible to use setlocal in command substitutions on ksh93.
# (Luckily, AT&T ksh also has LEPIPEMAIN, meaning, the last element of a pipe is
# executed in the main shell. This means you can still pipe the output of a
# command into a setlocal...endlocal block with no problem, provided that
# block is the last element of the pipe.)
# All of the above applies only to ksh93 and not to any other shell.
# However, this does mean portable scripts should NOT use setlocal in
# subshells other than background jobs and command substitutions.
#
# Usage:
# setlocal [ <item> [ <item> ... ] ] [ -- <arg> [ <arg> ... ] ]; do
#    <command> [ <command> ... ]
# endlocal
#	where <item> is a variable name, variable assignment, short- or
#	long-form shell option, or setlocal --split or --glob option. Unlike
#	with 'push', variables are unset or assigned, and shell options are set
#	(e.g. -f, -o noglob) or unset (e.g. +f, +o noglob), after pushing their
#	original values/settings onto the stack.
#	    If --split or --glob options are given, the <arg>s after the -- are
#	subjected to field spitting and/or globbing, without activating field
#	splitting or globbing within the setlocal block itself. These processed
#	<arg>s then become the positional parameters (PPs) within the setlocal
#	block. The --split option can have an argument (--split=chars) that
#	are the character(s) to split on, as in IFS.
#	    If no <arg>s are given, any --split or --glob options are ignored
#	and the setlocal block inherits an unchanged copy of the parent PPs.
#	    Note that the --split and --glob options do NOT activate field
#	splitting and globbing within the code block itself -- in fact the
#	point of those options is to safely split or glob arguments without
#	affecting any code. Local split and glob can be achieved simply by
#	adding the IFS variable and turning off 'noglob' (+f or +o noglob) like
#	any other <item>.
#
# Usage example:
#	setlocal IFS=',' +f -C somevar='Something'; do
#		commands
#		if <errorcondition>; then return 1; fi
#		morecommands
#	endlocal
#
#	setlocal mycmd=ls dir --split=':' -- $PATH; do
#		for dir do
#			if can exec $dir/$mycmd; then
#				putln "Found $dir/$mycmd!"
#				break
#			fi
#		done
#	endlocal
#
# Nesting setlocal...endlocal blocks also works; redefining the temporary
# function while another instance of it is running is not a problem because
# shells create an internal working copy of a function before executing it.
#
# WARNING: To avoid data corruption, never use 'continue' or 'break' within
# setlocal..endlocal unless the *entire* loop is within the setlocal block!
# A few shells (ksh, mksh) disallow this because they don't allow 'break' to
# interrupt the temporary shell function, but on others this will silently
# result in stack corruption and non-restoration of global variables and
# shell options. There is no way to block this.
#
# TODO: support local traps.
#
# --- begin license ---
# Copyright (c) 2016 Martijn Dekker <martijn@inlv.org>, Groningen, Netherlands
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
# --- end license ---

# The aliases below pass $LINENO on to the handling functions for use in error messages, so they can report
# the line number of the 'setlocal' or 'endlocal' where the error occurred. But on shells with BUG_LNNOALIAS
# (pdksh, mksh) this is pointless as the number is always zero when $LINENO is expanded from an alias.
if not thisshellhas LINENO || thisshellhas BUG_LNNOALIAS; then
	_Msh_sL_LINENO="''"
else
	_Msh_sL_LINENO='"${LINENO-}"'
fi

# ksh93: Due to BUG_FNSUBSH, this shell cannot unset or redefine a function within a non-forked subshell.
# 'unset -f' and function redefinitions in non-forked subshells are silently ignored without error, and the
# wrong code, i.e. that from the main shell, is re-executed! It's better to kill the program than to execute
# the wrong code. (The functions below must be defined using the 'function' keyword, or ksh93 will segfault.)
if thisshellhas BUG_FNSUBSH; then
	if not thisshellhas KSH93FUNC; then
		putln "var/setlocal: You're on a shell with BUG_FNSUBSH that is not ksh93! This" \
		      "              is not known to exist and cannot be handled. Please report." 1>&2
		return 1
	fi
	eval 'function _Msh_sL_BUG_FNSUBSH_dummyFn { :; }
	function _Msh_sL_ckSub {
		unset -f _Msh_sL_BUG_FNSUBSH_dummyFn
		if isset -f _Msh_sL_BUG_FNSUBSH_dummyFn; then
			die "setlocal: FATAL: Detected use of '\''setlocal'\'' in subshell on ksh93 with BUG_FNSUBSH."
			return
		fi
		function _Msh_sL_BUG_FNSUBSH_dummyFn { :; }
	}'
	_Msh_sL_ksh93=': 1>&-; _Msh_sL_ckSub && '
	#	       ^^^^^^ Make use of a ksh93 quirk: if this is a command substitution subshell, a dummy
	#		      output redirection within it will cause it to be forked, undoing BUG_FNSUBSH.
	#		      It has no effect in the main shell or in non-forked non-cmd.subst. subshells.
else
	_Msh_sL_ksh93=''
fi

# The pair of aliases.

alias setlocal="{ ${_Msh_sL_ksh93}"\
'_Msh_sL_temp() { isset _Msh_sL_PPs && eval "set -- ${_Msh_sL_PPs}"; while _Msh_doSetLocal '"${_Msh_sL_LINENO}"

alias endlocal='return; done; } || die; unset -v _Msh_sL _Msh_sL_PPs; '\
'_Msh_sL_temp || die; _Msh_sL_temp "$@"; _Msh_doEndLocal "$?" '"${_Msh_sL_LINENO}; }"

unset -v _Msh_sL_LINENO _Msh_sL_ksh93


# Internal functions that do the work. Not for direct use.

_Msh_doSetLocal() {
	case ${_Msh_sL-} in
	( y )	_Msh_sL=n
		return 0 ;;	# second call: ignore this and execute the block
	( n )	return 1 ;;	# third call (due to 'continue'): leave the block
	esac

	# line number for error message if we die (if shell has $LINENO)
	_Msh_sL_LN=$1
	shift

	unset -v _Msh_sL _Msh_sL_o _Msh_sL_splitd _Msh_sL_splitv _Msh_sL_glob

	# Validation; gather arguments for 'push' in ${_Msh_sL}.
	for _Msh_sL_A do
		case ${_Msh_sL_o-} in	# BUG_LOOPISSET compat: don't use ${_Msh_sL_o+s}
		( y )	if not thisshellhas -o "${_Msh_sL_A}"; then
				die "setlocal${_Msh_sL_LN:+ (line $_Msh_sL_LN)}: no such shell option: -o ${_Msh_sL_A}" || return
			fi
			_Msh_sL="${_Msh_sL+${_Msh_sL} }-o ${_Msh_sL_A}"
			unset -v _Msh_sL_o
			continue ;;
		esac
		case "${_Msh_sL_A}" in
		( -- )	break ;;
		( --split | --split=* | --glob )
			continue ;;
		( [-+]o )
			_Msh_sL_o=y	# expect argument
			continue ;;
		( [-+]["$ASCIIALNUM"] )
			if not thisshellhas "-${_Msh_sL_A#?}"; then
				die "setlocal${_Msh_sL_LN:+ (line $_Msh_sL_LN)}: no such shell option: ${_Msh_sL_A}" || return
			fi
			_Msh_sL_V="-${_Msh_sL_A#[-+]}" ;;
		( *=* )	_Msh_sL_V=${_Msh_sL_A%%=*} ;;
		( * )	_Msh_sL_V=${_Msh_sL_A} ;;
		esac
		case "${_Msh_sL_V}" in
		( -["$ASCIIALNUM"] )	# shell option: ok
			;;
		( '' | [0123456789]* | *[!"$ASCIIALNUM"_]* )
			die "setlocal${_Msh_sL_LN:+ (line $_Msh_sL_LN)}: invalid variable name or shell option: ${_Msh_sL_V}" \
			|| return ;;
		esac
		_Msh_sL="${_Msh_sL+${_Msh_sL} }${_Msh_sL_V}"
	done
	case ${_Msh_sL_o-} in
	( y )	die "setlocal${_Msh_sL_LN:+ (line $_Msh_sL_LN)}: ${_Msh_sL_A}: option requires argument" || return ;;
	esac

	# Push the global values/settings onto the stack.
	# (Since our input is now safely validated, abuse 'eval' for
	# field splitting so we don't have to bother with $IFS.)
	eval "push --key=_Msh_setlocal ${_Msh_sL-} _Msh_sL" || return

	# Apply local values/settings.
	while let "$#"; do
		case $1 in
		( -- )	break ;;
		( --split )
			_Msh_sL_splitd=y; unset -v _Msh_sL_splitv ;;
		( --split=* )
			_Msh_sL_splitv=${1#--split=}; unset -v _Msh_sL_splitd ;;
		( --glob )
			_Msh_sL_glob=y ;;
		( [+-]o )
			command set "$1" "$2" || die "setlocal${_Msh_sL_LN:+ (line $_Msh_sL_LN)}: 'set $1 $2' failed" || return
			shift ;;
		( [-+]["$ASCIIALNUM"] )
			command set "$1" || die "setlocal${_Msh_sL_LN:+ (line $_Msh_sL_LN)}: 'set $1' failed" || return ;;
		( *=* )	eval "${1%%=*}=\${1#*=}" ;;
		( * )	unset -v "$1" ;;
		esac
		shift
	done

	# If there are are arguments left, make them the positional parameters of the setlocal block.
	# First, if specified, subject them to field splitting and/or pathname expansion (globbing).
	# Then store them shellquoted in _Msh_sL_PPs for later eval'ing in the second temp function call.
	if let "$#"; then
		shift		# remove '--'
		_Msh_sL_PPs=''	# begin with empty set
		push IFS -f
		case ${_Msh_sL_splitv+v}${_Msh_sL_splitd+d} in
		( v )	IFS=${_Msh_sL_splitv} ;;
		( d )	unset -v IFS ;;		# shell default split
		( '' )	IFS='' ;;		# by default, don't split
		( * )	die "setlocal${_Msh_sL_LN:+ (line $_Msh_sL_LN)}: internal error" || return ;;
		esac
		case ${_Msh_sL_glob+g} in
		( g )	set +f ;;
		( '' )	set -f ;;
		esac
		for _Msh_sL_A do
			set -- ${_Msh_sL_A}	# do split and/or glob, if set
			for _Msh_sL_A do
				shellquote _Msh_sL_A
				_Msh_sL_PPs=${_Msh_sL_PPs:+${_Msh_sL_PPs} }${_Msh_sL_A}
			done
		done
		pop IFS -f
	else
		case ${_Msh_sL_splitv+v}${_Msh_sL_splitd+d} in
		( ?* )	die "setlocal${_Msh_sL_LN:+ (line $_Msh_sL_LN)}: --split or --glob require words to operate on" || return ;;
		esac
	fi

	unset -v _Msh_sL_V _Msh_sL_A _Msh_sL_o _Msh_sL_LN _Msh_sL_splitd _Msh_sL_splitv _Msh_sL_glob
	_Msh_sL=y
	return 1	# on the first call, don't execute the block
}

_Msh_doEndLocal() {
	# Unsetting the temp function makes ksh93 "AJM 93u+ 2012-08-01", the
	# latest release version as of 2016, segfault if setlocal...endlocal
	# blocks are nested.
	# So we don't do this:
	#unset -f _Msh_sL_temp

	pop --key=_Msh_setlocal _Msh_sL \
	|| die "endlocal${2:+ (line $2)}: stack corrupted (failed to pop arguments)" || return
	if isset _Msh_sL; then
		eval "pop --key=_Msh_setlocal ${_Msh_sL}" \
		|| die "endlocal${2:+ (line $2)}: stack corrupted (failed to pop globals)" || return
		unset -v _Msh_sL
	fi
	return "$1"
}
