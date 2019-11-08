#! /module/for/moderni/sh
\command unalias printstack 2>/dev/null

# var/stack/extra/printstack
#
# Outputs the contents of a variable or shell options's stack, top down, one
# item per line.
# Usage: printstack [ --quote ] <item>
# The <item> can be a variable name, a short/long shell option, or --trap=<signal>.
# Option --quote shell-quotes each stack value before printing it. This allows
# parsing of multi-line or otherwise complicated values.
# Column 1 to 7 of the output contain the number of the item (down to 0).
# If the item is set, column 8 and 9 contain a colon and a space, and
# if the value is non-empty or quoted, column 10 and up contain the value.
# Sets of values that were pushed with a key are started with the special
# string '--- key: <value>'. A subsequent set pushed with no key is
# started with the string '--- (key off)'.
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

use var/shellquote

# -----------------

printstack() {
	_Msh_pSo_Q=''
	while :; do
		case ${1-} in
		( -- )	shift; break ;;
		( --quote )
			_Msh_pSo_Q=yes ;;
		( -["$ASCIIALNUM"] | --trap=* )
			break ;;
		( -* )	die "stackempty: invalid option: $1" ;;
		( * )	break ;;
		esac
		shift
	done

	case ${#},$1 in
	( 1,--trap=* )
		_Msh_arg2sig "${1#--trap=}" || die "printstack: invalid signal specification: ${_Msh_sig}"
		set -- "_Msh_trap${_Msh_sigv}"
		unset -v _Msh_sig _Msh_sigv ;;
	( 1,-o )
		die "printstack: -o: one long-form option expected" ;;
	( 1,-["$ASCIIALNUM"] )
		set -- "_Msh_ShellOptLtr_${1#-}" ;;
	( 1, | 1,[0123456789]* | 1,*[!"$ASCIIALNUM"_]* )
		die "printstack: invalid variable name: $1" ;;
	( 1,* )	;;
	( 2,-o )
		_Msh_optNamToVar "$2" _Msh_pS_V || die "printstack: invalid long option name: $2"
		set -- "${_Msh_pS_V}"
		unset -v _Msh_pS_V ;;
	( * )	die "printstack: need 1 non-option argument, got $#" ;;
	esac

	# Return non-success if stack empty.
	if ! isset "_Msh__V${1}__SP"; then
		unset -v _Msh_pSo_Q
		return 1
	fi

	# Validate stack pointer.
	eval "_Msh_pS_i=\${_Msh__V${1}__SP}"
	case ${_Msh_pS_i} in
	( '' | *[!0123456789]* ) die "printstack: Stack pointer for $1 corrupted" ;;
	esac

	# Output the stack.
	unset -v _Msh_pS_key
	while let '(_Msh_pS_i-=1) >= 0'; do
		# print key, if changed from prev item
		if isset "_Msh__V${1}__K${_Msh_pS_i}"; then
			if ! eval "str eq \"\${_Msh_pS_key-}\" \"\${_Msh__V${1}__K${_Msh_pS_i}}\""; then
				eval "_Msh_pS_key=\${_Msh__V${1}__K${_Msh_pS_i}}"
				_Msh_pS_VAL=${_Msh_pS_key}
				case ${_Msh_pSo_Q:+n} in
				( n )	shellquote -f _Msh_pS_VAL ;;
				esac
				putln "--- key: ${_Msh_pS_VAL}"
			fi
		elif isset _Msh_pS_key; then
			unset -v _Msh_pS_key
			putln "--- (key off)"
		fi
		# print item
		if isset "_Msh__V${1}__S${_Msh_pS_i}"; then
			eval "_Msh_pS_VAL=\${_Msh__V${1}__S${_Msh_pS_i}}"
			case ${_Msh_pSo_Q:+n} in
			( n )	shellquote -f _Msh_pS_VAL ;;
			esac
			PATH=$DEFPATH command printf '%7d: %s\n' "${_Msh_pS_i}" "${_Msh_pS_VAL}"
		else
			PATH=$DEFPATH command printf '%7d\n' "${_Msh_pS_i}"
		fi || die "printstack: 'printf' failed"
	done

	unset -v _Msh_pS_i _Msh_pSo_Q _Msh_pS_VAL _Msh_pS_key
}

# -----------------

if thisshellhas ROFUNC; then
	readonly -f printstack
fi
