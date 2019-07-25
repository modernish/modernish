#! /module/for/moderni/sh
\command unalias clearstack 2>/dev/null

# var/stack/extra/clearstack
#
# Empties one or more variables' or shell options' stacks.
# Usage: clearstack [ --key=<value> ] [ --force ] <item> [ <item> ... ]
#
# If (part of) the stack is keyed or a --key is given, only clears until a key
# mismatch is encountered. '--force' overrides this and always clears the
# entire stack (be careful, e.g. don't use within LOCAL...BEGIN...END).
#
# Empties *nothing* if one of the specified items' stack is already
# empty or has nothing to clear due to a key mismatch.
# This allows for extra validation when treating several items as a group.
#
# Return status: 0 on success, 1 if stack was already empty, 2 if
# there was nothing to clear due to a key mismatch.
#
# --- begin license ---
# Copyright (c) 2019 Martijn Dekker <martijn@inlv.org>, Groningen, Netherlands
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

clearstack() {
	unset -v _Msh_cS_key _Msh_cS_f
	while :; do
		case ${1-} in
		( -- )	shift; break ;;
		( --key=* )
			_Msh_cS_key=${1#--key=} ;;
		( --force )
			_Msh_cS_f=y ;;
		( --trap=* | -o )
			break ;;
		( -* )	die "clearstack: invalid option: $1" ;;
		( * )	break ;;
		esac
		shift
	done
	case $# in
	( 0 )	die "clearstack: needs at least 1 non-option argument" ;;
	esac
	case ${_Msh_cS_key+k}${_Msh_cS_f+f} in
	( kf )	die "clearstack: options --key= and --force are mutually exclusive" ;;
	esac

	# Validate everything before doing anything
	_Msh_cS_err=0
	unset -v _Msh_cS_o
	for _Msh_cS_V do
		case ${_Msh_cS_o-} in		# BUG_ISSETLOOP compat: don't use ${_Msh_cS_o+s}
		( y )	_Msh_optNamToVar "${_Msh_cS_V}" _Msh_cS_V \
			|| die "clearstack: invalid long option name: ${_Msh_cS_V}"
			unset -v _Msh_cS_o ;;
		( * )	case ${_Msh_cS_V} in
			( --trap=* )
				use -q var/stack/trap || die "clearstack: --trap: requires var/stack/trap"
				_Msh_arg2sig "${_Msh_cS_V#--trap=}" \
				|| die "clearstack --trap: no such signal: ${_Msh_sig}"
				_Msh_clearAllTrapsIfFirstInSubshell
				_Msh_cS_V=_Msh_trap${_Msh_sigv} ;;
			( -o )	_Msh_cS_o=y	# expect another argument
				continue ;;
			( -["$ASCIIALNUM"] )
				_Msh_cS_V="_Msh_ShellOptLtr_${_Msh_cS_V#-}" ;;
			( '' | [0123456789]* | *[!"$ASCIIALNUM"_]* )
				die "clearstack: invalid variable name or shell option: $_Msh_cS_V" ;;
			esac ;;
		esac

		# Check for stack empty
		eval "_Msh_cS_SP=\${_Msh__V${_Msh_cS_V}__SP+s},\${_Msh__V${_Msh_cS_V}__SP-}"
		case ${_Msh_cS_SP} in
		( , )	_Msh_cS_err=$((_Msh_cS_err<1 ? 1 : _Msh_cS_err)); continue ;;  # stack empty
		( s, | s,0* | s,*[!0123456789]* )
			die "clearstack: Stack pointer for ${_Msh_cS_V} corrupted" ;;
		esac

		# Match stored key against given key, unless --force was given
		case ${_Msh_cS_f+s} in
		( "" )	_Msh_cS_SP=$((_Msh__V${_Msh_cS_V}__SP - 1))
			eval "case \${_Msh_cS_key+k},\${_Msh_cS_key-},\${_Msh__V${_Msh_cS_V}__K${_Msh_cS_SP}+s} in
			( ,, | k,\"\${_Msh__V${_Msh_cS_V}__K${_Msh_cS_SP}-}\",s )
				;;
			( * )	_Msh_cS_err=2 ;;
			esac" ;;
		esac
	done

	# Do the job
	case ${_Msh_cS_err} in
	( 0 ) for _Msh_cS_V do
		unset -v _Msh_cS_sST
		case ${_Msh_cS_o-} in
		( y )	_Msh_optNamToVar "${_Msh_cS_V}" _Msh_cS_V || die "clearstack: internal error"
			unset -v _Msh_cS_o ;;
		esac
		case ${_Msh_cS_V} in
		( --trap=* )
			_Msh_arg2sig "${_Msh_cS_V#--trap=}"
			push _Msh_cS_key _Msh_cS_f _Msh_cS_err
			clearstack ${_Msh_cS_f+"--force"} ${_Msh_cS_key+"--key=$_Msh_cS_key"} \
				"_Msh_trap${_Msh_sigv}_opt" "_Msh_trap${_Msh_sigv}_ifs" "_Msh_trap${_Msh_sigv}_noSub"
			pop _Msh_cS_key _Msh_cS_f _Msh_cS_err
			_Msh_cS_sST=	# remember to _Msh_setSysTrap later
			_Msh_cS_V=_Msh_trap${_Msh_sigv} ;;
		( -o )	_Msh_cS_o=y	# expect another argument
			continue ;;
		( -? )	_Msh_cS_V="_Msh_ShellOptLtr_${_Msh_cS_V#-}" ;;
		esac
		eval "_Msh_cS_SP=\${_Msh__V${_Msh_cS_V}__SP}"
		while let "(_Msh_cS_SP-=1) >= 0" &&
			# Clear until the key doesn't match, unless --force was given
			case ${_Msh_cS_f+s} in
			( "" )	eval "case \${_Msh_cS_key+k},\${_Msh_cS_key-},\${_Msh__V${_Msh_cS_V}__K${_Msh_cS_SP}+s} in
				( ,, | k,\"\${_Msh__V${_Msh_cS_V}__K${_Msh_cS_SP}-}\",s )
					;;
				( * )	! : ;;
				esac" ;;
			esac
		do
			unset -v "_Msh__V${_Msh_cS_V}__S${_Msh_cS_SP}" "_Msh__V${_Msh_cS_V}__K${_Msh_cS_SP}"
		done
		if let "_Msh_cS_SP >= 0"; then
			let "_Msh__V${_Msh_cS_V}__SP = _Msh_cS_SP + 1"
		else
			unset -v "_Msh__V${_Msh_cS_V}__SP"
		fi
		if isset _Msh_cS_sST; then
			_Msh_setSysTrap "${_Msh_sig}" "${_Msh_sigv}" || return
			unset -v _Msh_sig _Msh_sigv
		fi
	done;; esac
	eval "unset -v _Msh_cS_V _Msh_cS_SP _Msh_cS_key _Msh_cS_f _Msh_cS_err _Msh_cS_sST; return ${_Msh_cS_err}"
}


# -----------------

if thisshellhas ROFUNC; then
	readonly -f clearstack
fi
