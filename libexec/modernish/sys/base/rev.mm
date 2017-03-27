#! /module/for/moderni/sh

# modernish sys/text/rev
# 
# Writes specified files to standard output, reversing the order of
# characters in every line. This utility is provided because, while a binary
# 'rev' is included in most Linux, BSD and Mac OS X-based distributions,
# other Unixes like Solaris and older Mac OS X still don't include it.
#
# Please note: the ability of this 'rev' to deal correctly with UTF-8
# multibyte characters depends entirely on the shell it's run on. For
# instance, 'dash' will mess it up, 'yash' is fine.
#
# Usage: like 'rev' on Linux and BSD, which is like 'cat' except that '-' is
# a filename and does not denote standard input. No options are supported.
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

unset -v _Msh_rev_wMULTIBYTE
while let "$#"; do
	case "$1" in
	( -w )
		# declare that the program will work around a shell bug affecting sys/text/rev
		let "$# >= 2" || die "sys/text/rev: option requires argument: -w" || return
		case "$2" in
		( BUG_MULTIBYTE )	_Msh_rev_wMULTIBYTE=y ;;
		esac
		shift
		;;
	( -??* )
		# if option and option-argument are 1 argument, split them
		_Msh_rev_tmp=$1
		shift
		set -- "${_Msh_rev_tmp%"${_Msh_rev_tmp#-?}"}" "${_Msh_rev_tmp#-?}" "$@"			# "
		unset -v _Msh_rev_tmp
		continue
		;;
	( * )
		putln "sys/text/rev: invalid option: $1" 1>&2
		return 1
		;;
	esac
	shift
done
if thisshellhas BUG_MULTIBYTE && not isset _Msh_rev_wMULTIBYTE; then
	putln 'sys/text/rev: You'\''re running a shell with BUG_MULTIBYTE, which can'\''t deal' \
	      '         correctly with multibyte UTF-8 characters. This would corrupt the' \
	      '         output of '\''rev'\'' if the input file contains these. To use sys/text/rev' \
	      '         in a BUG_MULITBYTE compatible way, add the option "-w BUG_MULTIBYTE" and' \
	      '         carefully write your program to avoid processing multibyte characters' \
	      '         using this implementation of '\''rev'\''.' \
	      1>&2
	return 1
fi
unset -v _Msh_rev_wMULTIBYTE

_Msh_doRevLine() {
	while let "${#_Msh_revL}"; do
		_Msh_revC=${_Msh_revL}
		_Msh_revL=${_Msh_revL%?}
		_Msh_revC=${_Msh_revC#"$_Msh_revL"}
		put "${_Msh_revC}"
	done
}

rev() {
	if let "$#"; then
		_Msh_revE=0
		for _Msh_revA do
			case ${_Msh_revA} in
			#( - )	rev ;;	# '-' is not supported for compatibility with BSD/Linux 'rev'
			( * )	if not is -L present "${_Msh_revA}"; then
					putln "rev: ${_Msh_revA}: File not found" 1>&2
					_Msh_revE=1
					continue
				elif is -L dir "${_Msh_revA}"; then
					putln "rev: ${_Msh_revA}: Is a directory" 1>&2
					_Msh_revE=1
					continue
				fi
				rev < "${_Msh_revA}" ;;
			esac || _Msh_revE=1
		done
		eval "unset -v _Msh_revA _Msh_revE; return ${_Msh_revE}"
	fi
	while IFS='' read -r _Msh_revL; do
		_Msh_doRevLine
		putln	# newline
	done
	# also output any possible last line without final newline
	# [note: native 'rev' on Mac OS X does output an extra final
	# newline, linuxutils 'rev' doesn't]
	if not empty "${_Msh_revL}"; then
		_Msh_doRevLine
	fi
	unset -v _Msh_revL _Msh_revC
}

if thisshellhas ROFUNC; then
	readonly -f _Msh_doRevLine rev
fi
