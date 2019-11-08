#! /module/for/moderni/sh
\command unalias append prepend 2>/dev/null

# var/string/append
#
# append: Append zero or more strings to a variable, separated by a string of
# zero or more characters, avoiding the hairy problem of dangling separators.
#
# Usage: append [ --sep=<separator> ] [ -Q ] <varname> [ <string> ... ]
# If the separator is not specified, it defaults to a space character.
# If the -Q option is given, each <string> is shell-quoted before appending.
#
# For one <string>, this function is equivalent to the following incantation:
#	var=${var:+$var$separator}$string
# or (on shells with ADDASSIGN)
#	var+=${var:+$separator}$string
# Example: append --sep=: PATH "$HOME/bin" "$HOME/sbin"
#	   append --sep=/ textfiles *.txt
#
# (This function uses a GNU-style long option of the form --sep=<separator>
# because it is a safer way of dealing with empty removal. With a classical
# option format such as '-s <separator>' or '-s<separator>', even under 'use
# safe', if the separator is passed from an empty variable, the variable
# name will be taken as the separator, and the first string as the variable
# name. Also, due to the way the shell removes quotes before passing
# arguments to commands, a zero character separator could never be stacked
# with an -s option in a single word, even if it is quoted -- it has to be a
# separate empty word. The GNU long option format avoids both these snags,
# allowing an empty separator to be safely passed from an unquoted variable
# under 'use safe'.)
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

if thisshellhas ADDASSIGN ARITHCMD ARITHPP; then
	# Use additive assignment var+=value as an optimization if available.
	# (Every shell I know that has ADDASSIGN also has ARITHCMD and ARITHPP; might as well use them.)
	append() {
		_Msh_aS_Q=n
		_Msh_aS_s=' '
		while	case ${1-} in
			( --sep=* )
				_Msh_aS_s=${1#--sep=} ;;
			( -Q )	_Msh_aS_Q=y ;;
			( -- )	! shift ;;
			( -* )	die "append: invalid option: $1" ;;
			( * )	! : ;;
			esac
		do
			shift
		done
		case ${_Msh_aS_Q},${#},${1-},${_Msh_aS_s} in
		( ?,0,,"${_Msh_aS_s}" )
			die "append: variable name expected" ;;
		( ?,"$#",,"${_Msh_aS_s}" | ?,"$#",[0123456789]*,"${_Msh_aS_s}" | ?,"$#",*[!"$ASCIIALNUM"_]*,"${_Msh_aS_s}" )
			die "append: invalid variable name: $1" ;;

		# no strings: no-op (in case of empty removal)
		( ?,1,* ) ;;

		# single string
		( n,2,* )
			eval "$1+=\${$1:+\${_Msh_aS_s}}\$2" ;;

		# multiple strings with empty or one character separator: use optimization with "$*" and IFS
		# ref.: http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_05_02
		( n,*,"${1-}", | n,*,"${1-}",? )
			isset IFS && _Msh_aS_IFS=$IFS || unset -v _Msh_aS_IFS
			IFS=${_Msh_aS_s}
			eval "shift; $1+=\${$1:+\$IFS}\$*"
			isset _Msh_aS_IFS && IFS=${_Msh_aS_IFS} && unset -v _Msh_aS_IFS || unset -v IFS ;;

		# multiple strings with multiple character separator: use a loop
		( n,* )	_Msh_aS_i=2
			while ((++_Msh_aS_i < $#)); do	# ARITHCMD, ARITHPP
				eval "$1+=\${$1:+\${_Msh_aS_s}}\${${_Msh_aS_i}}"
			done
			unset -v _Msh_aS_i ;;

		# single string (with shell quoting)
		( y,2,* )
			shellquote -f _Msh_aS_V="$2"
			eval "$1+=\${$1:+\${_Msh_aS_s}}\${_Msh_aS_V}"
			unset -v _Msh_aS_V ;;

		# multiple strings (with shell quoting)
		( y,* )	_Msh_aS_i=2
			while ((++_Msh_aS_i < $#)); do	# ARITHCMD, ARITHPP
				eval "shellquote -f _Msh_aS_V=\"\${${_Msh_aS_i}}\"
					$1+=\${$1:+\${_Msh_aS_s}}\${_Msh_aS_V}"
			done
			unset -v _Msh_aS_i _Msh_aS_V ;;
		esac

		unset -v _Msh_aS_s _Msh_aS_Q
	}
else
	append() {
		_Msh_aS_Q=n
		_Msh_aS_s=' '
		while	case ${1-} in
			( --sep=* )
				_Msh_aS_s=${1#--sep=} ;;
			( -Q )	_Msh_aS_Q=y ;;
			( -- )	! shift ;;
			( -* )	die "append: invalid option: $1" ;;
			( * )	! : ;;
			esac
		do
			shift
		done
		case ${_Msh_aS_Q},${#},${1-},${_Msh_aS_s} in
		( ?,0,,"${_Msh_aS_s}" )
			die "append: variable name expected" ;;
		( ?,"$#",,"${_Msh_aS_s}" | ?,"$#",[0123456789]*,"${_Msh_aS_s}" | ?,"$#",*[!"$ASCIIALNUM"_]*,"${_Msh_aS_s}" )
			die "append: invalid variable name: $1" ;;

		# no strings: no-op (in case of empty removal)
		( ?,1,* ) ;;

		# single string
		( n,2,* )
			eval "$1=\${$1:+\$$1\${_Msh_aS_s}}\$2" ;;

		# multiple strings with empty or one character separator: use optimization with "$*" and IFS
		# ref.: http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_05_02
		( n,*,"${1-}", | n,*,"${1-}",? )
			isset IFS && _Msh_aS_IFS=$IFS || unset -v _Msh_aS_IFS
			IFS=${_Msh_aS_s}
			eval "shift; $1=\${$1:+\$$1\$IFS}\$*"
			isset _Msh_aS_IFS && IFS=${_Msh_aS_IFS} && unset -v _Msh_aS_IFS || unset -v IFS ;;

		# multiple strings with multiple character separator: use a loop
		( n,* )	_Msh_aS_i=1
			while let "(_Msh_aS_i+=1) <= $#"; do
				eval "$1=\${$1:+\$$1\${_Msh_aS_s}}\${${_Msh_aS_i}}"
			done
			unset -v _Msh_aS_i ;;

		# single string (with shell quoting)
		( y,2,* )
			shellquote -f _Msh_aS_V="$2"
			eval "$1=\${$1:+\$$1\${_Msh_aS_s}}\${_Msh_aS_V}"
			unset -v _Msh_aS_V ;;

		# multiple strings (with shell quoting)
		( y,* )	_Msh_aS_i=1
			while let "(_Msh_aS_i+=1) <= $#"; do
				eval "shellquote -f _Msh_aS_V=\"\${${_Msh_aS_i}}\"
					$1=\${$1:+\$$1\${_Msh_aS_s}}\${_Msh_aS_V}"
			done
			unset -v _Msh_aS_i _Msh_aS_V ;;
		esac

		unset -v _Msh_aS_s _Msh_aS_Q
	}
fi

# prepend: Exactly like append() but adds strings at the start instead of
# the end (but without reversing the order they are specified in).
# For one <string>, this is equivalent to the following incantation:
#	var=$string${var:+$separator$var}
prepend() {
	_Msh_pS_Q=n
	_Msh_pS_s=' '
	while	case ${1-} in
		( --sep=* )
			_Msh_pS_s=${1#--sep=} ;;
		( -Q )	_Msh_pS_Q=y ;;
		( -- )	! shift ;;
		( -* )	die "prepend: invalid option: $1" ;;
		( * )	! : ;;
		esac
	do
		shift
	done
	case ${_Msh_pS_Q},${#},${1-},${_Msh_pS_s} in
	( ?,0,,"${_Msh_pS_s}" )
		die "prepend: variable name expected" ;;
	( ?,"$#",,"${_Msh_pS_s}" | ?,"$#",[0123456789]*,"${_Msh_pS_s}" | ?,"$#",*[!"$ASCIIALNUM"_]*,"${_Msh_pS_s}" )
		die "prepend: invalid variable name: $1" ;;

	# no strings: no-op (in case of empty removal)
	( ?,1,* ) ;;

	# single string
	( n,2,* )
		eval "$1=\$2\${$1:+\${_Msh_pS_s}\$$1}" ;;

	# multiple strings with empty or one character separator: use optimization with "$*" and IFS
	# ref.: http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_05_02
	( n,*,"${1-}", | n,*,"${1-}",? )
		isset IFS && _Msh_pS_IFS=$IFS || unset -v _Msh_pS_IFS
		IFS=${_Msh_pS_s}
		eval "shift; $1=\$*\${$1:+\$IFS\$$1}"
		isset _Msh_pS_IFS && IFS=${_Msh_pS_IFS} && unset -v _Msh_pS_IFS || unset -v IFS ;;

	# multiple strings with multiple character separator: use a loop
	( n,* )	let "_Msh_pS_i=${#}+1"
		while let "(_Msh_pS_i-=1) >= 2"; do
			eval "$1=\${${_Msh_pS_i}}\${$1:+\${_Msh_pS_s}\$$1}"
		done
		unset -v _Msh_pS_i ;;

	# single string (with shell quoting)
	( y,2,* )
		shellquote -f _Msh_pS_V="$2"
		eval "$1=\${_Msh_pS_V}\${$1:+\${_Msh_pS_s}\$$1}"
		unset -v _Msh_pS_V ;;

	# multiple strings (with shell quoting)
	( y,* )	let "_Msh_pS_i=${#}+1"
		while let "(_Msh_pS_i-=1) >= 2"; do
			eval "shellquote -f _Msh_pS_V=\"\${${_Msh_pS_i}}\"
				$1=\${_Msh_pS_V}\${$1:+\${_Msh_pS_s}\$$1}"
		done
		unset -v _Msh_pS_i _Msh_pS_V ;;
	esac

	unset -v _Msh_pS_s _Msh_pS_Q
}

if thisshellhas ROFUNC; then
	readonly -f append prepend
fi
