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
# Nesting setlocal...endlocal blocks also works; redefining the temporary
# function while another instance of it is not a problem because shells
# create an internal working copy of a function before executing it.
# However, a few buggy shells segfault when you nest these, so for maximum
# portability, avoid nesting.
#
# WARNING: Don't pop any of the local variables or settings within the
# block; (at least not unless you locally push them first); this will screw
# up the main stack and 'endlocal' will be unable to restore the global
# state properly.
#
# TODO: implement a key option for push/pop, and use it here to protect
# globals from being accidentially popped within a setlocal..endlocal block.

# Unsetting the temp function while it's running makes at least one version
# of ksh93 segfault; wasting a few kB by not unsetting it doesn't really
# hurt anything, and allows ksh93 to use nested setlocal. So we don't do this:
#alias setlocal='{ _Msh_sL_temp() { unset -f _Msh_sL_temp; _Msh_doSetLocal'


# The pair of aliases. (Enclosing everything in an extra { } allows you to 
# pipe or redirect an entire setlocal..endlocal block like any other block.)

alias setlocal='{  _Msh_sL_temp() { _Msh_doSetLocal "${LINENO-}"'
if isset MSH_HASBUG_UPP; then
	alias endlocal='} && { [ "$#" -gt 0 ] && _Msh_sL_temp "$@" || _Msh_sL_temp; _Msh_doEndLocal "$?" "${LINENO-}"; }; }'
else
	alias endlocal='} && { _Msh_sL_temp "$@"; _Msh_doEndLocal "$?" "${LINENO-}"; }; }'
fi

# Internal functions that do the work. Not for direct use.

_Msh_doSetLocal() {
	# line number for error message if we die (if shell has $LINENO)
	_Msh_sL_LN="$1"
	shift

	unset -v _Msh_sL

	# Validation; gather arguments for 'push' in ${_Msh_sL}.
	# (the $# test is for BUG_UPP compatibility)
	[ "$#" -gt 0 ] && for _Msh_sL_A do
		case "${_Msh_sL_A}" in
		( --dofieldsplitting | --nofieldsplitting | --fieldsplitting=* )
			_Msh_sL_V='IFS'
			;;
		( --doglobbing | --noglobbing )
			_Msh_sL_V='-f'
			;;
		( [-+]o* )
			if [ "${_Msh_sL_A#[-+]}" = 'o' ]; then
				if [ "$#" -lt 1 ]; then
					die "setlocal${_Msh_sL_LN:+ (line $_Msh_sL_LN)}: -o: option requires argument" || return
				fi
				shift
				_Msh_sL_o="$1"
			else
				_Msh_sL_o="${_Msh_sL_A#[-+]o}"
				if [ -z "${_Msh_sL_o}" ]; then
					die "setlocal${_Msh_sL_LN:+ (line $_Msh_sL_LN)}: -o: option requires argument" || return
				fi
			fi
			case "${_Msh_sL_o}" in
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
					_Msh_sL_V="${_Msh_sL_A}" ;;
			esac
			;;
		( [-+][abCfhmnuvx] )
			_Msh_sL_V="-${_Msh_sL_A#[-+]}"
			;;
		( *=* )
			_Msh_sL_V="${_Msh_sL_A%%=*}"
			;;
		( * )
			_Msh_sL_V="${_Msh_sL_A}"
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
	[ "$#" -gt 0 ] && for _Msh_sL_A do
		case "${_Msh_sL_A}" in
		( --dofieldsplitting )
			IFS=" ${CCt}${CCn}"
			;;
		( --nofieldsplitting )
			IFS=''
			;;
		( --fieldsplitting=* )
			IFS="${_Msh_sL_A#--fieldsplitting=}"
			;;
		( --doglobbing )
			set +f
			;;
		( --noglobbing )
			set -f
			;;
		( [-+]o* )
			if [ "${_Msh_sL_A#[-+]}" = 'o' ]; then
				shift
				_Msh_sL_A="${_Msh_sL_A}${1}"
			fi
			set "${_Msh_sL_A}" || die "setlocal${_Msh_sL_LN:+ (line $_Msh_sL_LN)}: 'set ${_Msh_sL_A}' failed" || return
			;;
		( [-+][abcdefghijklmnpqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ] )
			set "${_Msh_sL_A}" || die "setlocal${_Msh_sL_LN:+ (line $_Msh_sL_LN)}: 'set ${_Msh_sL_A}' failed" || return
			;;
		( *=* )
			eval "${_Msh_sL_A%%=*}=\"\${_Msh_sL_A#*=}\""
			;;
		( * )
			unset -v "${_Msh_sL_A}"
			;;
		esac
	done
	unset -v _Msh_sL _Msh_sL_V _Msh_sL_A _Msh_sL_o _Msh_sL_LN
}

_Msh_doEndLocal() {
	pop _Msh_sL || die "endlocal${2:+ (line $2)}: stack corrupted (failed to pop arguments)" || return
	if isset _Msh_sL; then
		eval "pop ${_Msh_sL}" || die "endlocal${2:+ (line $2)}: stack corrupted (failed to pop globals)" || return
		unset -v _Msh_sL
	fi
	return "$1"
}
