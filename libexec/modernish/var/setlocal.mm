#! /module/for/moderni/sh
# --- setlocal/endlocal ---
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
# be used within subshells; if you do, it will silently execute the WRONG code,
# i.e. that from an earlier setlocal...endlocal invocation in the main shell!
# [02-Jan-2016] I have now found a way to detect this so that setlocal will
#		kill the program rather than execute the wrong code.
# (Luckily, AT&T ksh also has LEPIPEMAIN, meaning, the last element of a pipe is
# executed in the main shell. This means you can still pipe the output of a
# command into a setlocal...endlocal block with no problem, provided that block
# is the last element of the pipe.)
# To declare BUG_FNSUBSH compatibility, 'use var/setlocal -w BUG_FNSUBSH'.
#
# Usage:
# setlocal <item> [ <item> ... ]
#    <command> [ <command> ... ]
# endlocal
#	where <item> is a variable name, variable assignment, or shell
#	option. Unlike with 'push', variables are unset or assigned, and
#	shell options are set (e.g. -f) or unset (e.g. +f), after pushing
#	their original values/settings onto the stack.
#
# Usage example:
#	setlocal IFS=',' +f -C somevar='Something'
#		commands
#		if <errorcondition>; then return 1; fi
#		morecommands
#	endlocal
#
# There are also a few convenience/readability synonyms:
#     setlocal --dosplit	= setlocal IFS=" $CCt$CCn"
#     setlocal --nosplit	= setlocal IFS=''
#     setlocal --split='STRING'	= setlocal IFS='STRING'
#     setlocal --doglob		= setlocal +f
#     setlocal --noglob		= setlocal -f
#
# Nesting setlocal...endlocal blocks also works; redefining the temporary
# function while another instance of it is running is not a problem because
# shells create an internal working copy of a function before executing it.
#
# WARNING: Don't pop any of the local variables or settings within the
# block; (at least not unless you locally push them first); this will screw
# up the main stack and 'endlocal' will be unable to restore the global
# state properly.
#
# WARNING: For the same reason, never use 'continue' or 'break' within
# setlocal..endlocal unless the *entire* loop is within the setlocal block!
# A few shells (ksh, mksh) disallow this because they don't allow 'break' to
# interrupt the temporary shell function, but on others this will silently
# result in stack corruption and non-restoration of global variables and
# shell options. There is no way to block this.
#
# TODO? implement a key option for push/pop, and use it here to protect
# globals from being accidentially popped within a setlocal..endlocal block.
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

# ---- Initialization: parse options, test & warn ----

unset -v _Msh_setlocal_wFNSUBSH
while let "$#"; do
	case "$1" in
	( -w )
		# declare that the program will work around a shell bug affecting 'use var/setlocal'
		let "$# >= 2" || die "use var/setlocal: option requires argument: -w" || return
		case "$2" in
		( BUG_FNSUBSH )	_Msh_setlocal_wFNSUBSH=y ;;
		esac
		shift
		;;
	( -??* )
		# if option and option-argument are 1 argument, split them
		_Msh_setlocal_tmp=$1
		shift
		if let "$#"; then	# BUG_UPP workaround, BUG_PARONEARG compatible
			set -- "${_Msh_setlocal_tmp%"${_Msh_setlocal_tmp#-?}"}" "${_Msh_setlocal_tmp#-?}" "$@"
		else
			set -- "${_Msh_setlocal_tmp%"${_Msh_setlocal_tmp#-?}"}" "${_Msh_setlocal_tmp#-?}"
		fi
		unset -v _Msh_setlocal_tmp
		continue
		;;
	( * )
		print "use var/setlocal: invalid option: $1"
		return 1
		;;
	esac
	shift
done

if thisshellhas BUG_FNSUBSH && not contains "$-" i; then
	if not isset _Msh_setlocal_wFNSUBSH; then
		print 'setlocal: This shell has BUG_FNSUBSH, a bug that causes it to ignore shell' \
		      '          functions redefined within a subshell. setlocal..endlocal depends' \
		      '          on this. To use setlocal in a BUG_FNSUBSH compatible way, add the' \
		      '          "-w BUG_FNSUBSH" option to "use var/setlocal" to suppress this' \
		      '          error message, and write your script to avoid setlocal..endlocal' \
		      '          in subshells.' 1>&2
		return 1
	else
		unset -v _Msh_setlocal_wFNSUBSH
	fi
fi

# ----- The actual thing starts here -----

# The pair of aliases. (Enclosing everything in an extra { } allows you to 
# pipe or redirect an entire setlocal..endlocal block like any other block.)

if thisshellhas ANONFUNC; then
	# zsh: an anonymous function is very convenient here; anonymous
	# functions are basically the native zsh equivalent of setlocal.
	alias setlocal='{ () { _Msh_doSetLocal "${LINENO-}"'
	alias endlocal='} "$@"; _Msh_doEndLocal "$?" "${LINENO-}"; }'
else
	if thisshellhas BUG_FNSUBSH KSH93FUNC ARITHCMD && ( eval '[[ -n ${.sh.subshell+s} ]]' ); then
		# ksh93: Due to BUG_FNSUBSH, this shell cannot unset or
		# redefine a function within a subshell. Unset and function
		# definition in subshells is silently ignored without error,
		# and the wrong code, i.e. that from the main shell, is
		# re-executed! It's better to kill the program than to execute
		# the wrong code. ksh93 helpfully provides the proprietary
		# ${.sh.subshell} to check the current subshell level. (Using
		# 'eval' to avoid syntax errors at parse time on other shells.)
		eval 'function _Msh_sL_ckSub {
			(( ${.sh.subshell} == 0 )) \
			|| die "setlocal: FATAL: Detected use of '\''setlocal'\'' in subshell on ksh93 with BUG_FNSUBSH."
		}'
		alias setlocal='{ _Msh_sL_ckSub && _Msh_sL_temp() { _Msh_doSetLocal "${LINENO-}"'
	else
		alias setlocal='{ _Msh_sL_temp() { _Msh_doSetLocal "${LINENO-}"'
	fi
	if thisshellhas BUG_UPP; then
		alias endlocal='} && { _Msh_sL_temp ${1+"$@"}; _Msh_doEndLocal "$?" "${LINENO-}"; }; }'
	else
		alias endlocal='} && { _Msh_sL_temp "$@"; _Msh_doEndLocal "$?" "${LINENO-}"; }; }'
	fi
fi 2>/dev/null


# Internal functions that do the work. Not for direct use.

_Msh_doSetLocal() {
	# line number for error message if we die (if shell has $LINENO)
	_Msh_sL_LN=$1
	shift

	unset -v _Msh_sL

	# Validation; gather arguments for 'push' in ${_Msh_sL}.
	let "$#" &&  # BUG_UPP workaround, BUG_PARONEARG compatible
	for _Msh_sL_A do
		case "${_Msh_sL_A}" in
		( --dosplit | --nosplit | --split=* )
			_Msh_sL_V='IFS'
			;;
		( --doglob | --noglob )
			_Msh_sL_V='-f'
			;;
		( [-+]o* )
			if match "${_Msh_sL_A}" '[-+]o'; then
				if let "$# < 1"; then
					die "setlocal${_Msh_sL_LN:+ (line $_Msh_sL_LN)}: -o: option requires argument" || return
				fi
				shift
				_Msh_sL_o=$1
			else
				_Msh_sL_o=${_Msh_sL_A#[-+]o}
				if empty "${_Msh_sL_o}"; then
					die "setlocal${_Msh_sL_LN:+ (line $_Msh_sL_LN)}: -o: option requires argument" || return
				fi
			fi
			case ${_Msh_sL_o} in
			( allexport )	_Msh_sL_V='-a' ;;
			#( errexit )	_Msh_sL_V='-e' ;;	# modernish doesn't support this
			( monitor )	_Msh_sL_V='-m' ;;
			( noclobber )	_Msh_sL_V='-C' ;;
			( noglob )	_Msh_sL_V='-f' ;;
			( noexec )	_Msh_sL_V='-n' ;;
			( notify )	_Msh_sL_V='-b' ;;
			( nounset )	_Msh_sL_V='-u' ;;
			( verbose )	_Msh_sL_V='-v' ;;
			( xtrace )	_Msh_sL_V='-x' ;;
			( * )		# trigger error
					_Msh_sL_V=${_Msh_sL_A} ;;
			esac
			;;
		( [-+][abCfhmnuvx] )
			_Msh_sL_V="-${_Msh_sL_A#[-+]}"
			;;
		( *=* )
			_Msh_sL_V=${_Msh_sL_A%%=*}
			;;
		( * )
			_Msh_sL_V=${_Msh_sL_A}
			;;
		esac
		case "${_Msh_sL_V}" in
		( -[abcdefghijklmnpqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ] )
			# shell option: ok
			;;
		( '' | [0123456789]* | *[!${ASCIIALNUM}_]* | *__[VS]* )
			die "setlocal${_Msh_sL_LN:+ (line $_Msh_sL_LN)}: invalid variable name or shell option: ${_Msh_sL_V}" || return
			;;
		esac
		_Msh_sL="${_Msh_sL+${_Msh_sL} }${_Msh_sL_V}"
	done

	# Push the global values/settings onto the stack.
	# (Since our input is now safely validated, abuse 'eval' for
	# field splitting so we don't have to bother with $IFS.)
	eval "push ${_Msh_sL-} _Msh_sL" || return

	# Apply local values/settings.
	let "$#" &&  # BUG_UPP workaround, BUG_PARONEARG compatible
	for _Msh_sL_A do
		case "${_Msh_sL_A}" in
		( --dosplit )
			IFS=" ${CCt}${CCn}"
			;;
		( --nosplit )
			IFS=''
			;;
		( --split=* )
			IFS=${_Msh_sL_A#--split=}
			;;
		( --doglob )
			set +f
			;;
		( --noglob )
			set -f
			;;
		( [-+]o* )
			if match "${_Msh_sL_A}" '[-+]o'; then
				shift
				_Msh_sL_A=${_Msh_sL_A}${1}
			fi
			# 'command' disables 'special built-in' properties, incl. exit shell on error,
			# except on shells with BUG_CMDSPCIAL
			command set "${_Msh_sL_A}" \
			|| die "setlocal${_Msh_sL_LN:+ (line $_Msh_sL_LN)}: 'set ${_Msh_sL_A}' failed" || return
			;;
		( [-+][abcdefghijklmnpqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ] )
			command set "${_Msh_sL_A}" \
			|| die "setlocal${_Msh_sL_LN:+ (line $_Msh_sL_LN)}: 'set ${_Msh_sL_A}' failed" || return
			;;
		( *=* )
			eval "${_Msh_sL_A%%=*}=\${_Msh_sL_A#*=}"
			;;
		( * )
			unset -v "${_Msh_sL_A}"
			;;
		esac
	done
	unset -v _Msh_sL _Msh_sL_V _Msh_sL_A _Msh_sL_o _Msh_sL_LN
}

_Msh_doEndLocal() {
	# Unsetting the temp function makes ksh93 "AJM 93u+ 2012-08-01", the
	# latest release version as of 2016, segfault if setlocal...endlocal
	# blocks are nested. Wasting a few kB by not unsetting it doesn't
	# really hurt anything, and allows recent ksh93 to use nested
	# setlocal.
	# OTOH, unsetting the function would circumvent BUG_FNSUBSH as long
	# as nested setlocal and setlocal within subshells aren't combined.
	# But it's probably not worth the price of crashing recent ksh93
	# just for using simple nesting without subshells.
	# So we don't do this:
	#unset -f _Msh_sL_temp

	pop _Msh_sL || die "endlocal${2:+ (line $2)}: stack corrupted (failed to pop arguments)" || return
	if isset _Msh_sL; then
		eval "pop ${_Msh_sL}" || die "endlocal${2:+ (line $2)}: stack corrupted (failed to pop globals)" || return
		unset -v _Msh_sL
	fi
	return "$1"
}
