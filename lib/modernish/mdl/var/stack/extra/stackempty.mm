#! /module/for/moderni/sh
\command unalias stackempty 2>/dev/null

# var/stack/extra/stackempty
#
# stackempty: Check if there is anything left to pop on a stack. Returns 0
# (true) if the stack is empty or there is a key mismatch, 1 (false) if not.
# Usage:  stackempty [ --force ] [ --key=<value> ] <item>
# '--force' ignores keys altogether. The <item> can be either
# '--trap=' plus a signal name to check a signal's trap stack, '-' plus
# a shell option letter to check a short-form shell option's stack, '-o'
# plus a separate argument to check a long-form shell option's stack, or
# a variable name to check a variable's stack.
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

# -----------------

stackempty() {
	unset -v _Msh_stkE_K _Msh_stkE_f
	while :; do
		case ${1-} in
		( -- )	shift; break ;;
		( --key=* )
			_Msh_stkE_K=${1#--key=} ;;
		( --force )
			_Msh_stkE_f=y ;;
		( -["$ASCIIALNUM"] | --trap=* )
			break ;;
		( -* )	die "stackempty: invalid option: $1" ;;
		( * )	break ;;
		esac
		shift
	done
	case ${#},${1-} in
	( 1,--trap=* )
		use -q var/stack/trap || die "stackempty: --trap: requires var/stack/trap"
		_Msh_arg2sig "${1#--trap=}" || die "stackempty: no such signal: ${_Msh_sig}"
		_Msh_stkE_V=_Msh_trap${_Msh_sigv}
		unset -v _Msh_sig _Msh_sigv ;;
	( 1,-o )
		die "stackempty: -o: one long-form option expected" ;;
	( 1,-["$ASCIIALNUM"] )
		_Msh_stkE_V=_Msh_ShellOptLtr_${1#-} ;;
	( 1, | 1,[0123456789]* | 1,*[!"$ASCIIALNUM"_]* )
		die "stackempty: invalid variable name or shell option: $1" ;;
	( 1,* )	_Msh_stkE_V=$1 ;;
	( 2,-o )
		_Msh_optNamToVar "$2" _Msh_stkE_V || die "stackempty: invalid long option name: $2" ;;
	( * )	die "stackempty: needs exactly 1 non-option argument" ;;
	esac
	case ${_Msh_stkE_f+f} in
	( f )	! isset "_Msh__V${_Msh_stkE_V}__SP" ;;
	( "" )	! isset "_Msh__V${_Msh_stkE_V}__SP" \
		|| ! eval "str eq \"\${_Msh_stkE_K+s},\${_Msh_stkE_K-}\" \
\"\${_Msh__V${_Msh_stkE_V}__K$((_Msh__V${_Msh_stkE_V}__SP-1))+s},\${_Msh__V${_Msh_stkE_V}__K$((_Msh__V${_Msh_stkE_V}__SP-1))-}\"" ;;
	esac
	eval "unset -v _Msh_stkE_V _Msh_stkE_K _Msh_stkE_f; return $?"
}

# -----------------

if thisshellhas ROFUNC; then
	readonly -f stackempty
fi
