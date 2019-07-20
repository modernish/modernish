#! /module/for/moderni/sh
\command unalias trim 2>/dev/null

# var/string/trim
#
# trim: Strip whitespace (or other characters) from the beginning and end of
# a variable's value. Whitespace is defined by the 'space' character class
# (in the POSIX locale, this is tab, newline, vertical tab, form feed,
# carriage return, and space, but in other locales it may be different).
# Optionally, a string of literal characters to trim can be provided in the
# second argument; any of those characters will be trimmed from the beginning
# and end of the variable's value.
# Usage: trim <varname> [ <characters> ]
# TODO: options -l and -r for trimming on the left or right only.
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

if thisshellhas BUG_NOCHCLASS; then
	# POSIX character classes such as [:space:] are buggy or unavailable,
	# so use modernish $WHITESPACE instead.  This means no locale-specific
	# whitespace matching.
	_Msh_trim_whitespace=\'$WHITESPACE\'
else
	_Msh_trim_whitespace=[:space:]
fi
if thisshellhas BUG_BRACQUOT; then
	# BUG_BRACQUOT: ksh93 and zsh don't disable the special meaning of
	# characters -, ! and ^ in quoted bracket expressions (even if their
	# values were passed in variables), so e.g. 'trim var a-d' would trim
	# on 'a', 'b', 'c' and 'd', not 'a', '-' and 'd'.
	# This workaround version makes sure '-' is last in the string, which
	# is the standard way of providing a literal '-' in an unquoted bracket
	# expression.
	# A workaround for an initial '!' or '^' is not needed because the
	# bracket expression in the command substitutions below start with a
	# negating '!' anyway, which makes sure any further '!' or '^' don't
	# have any special meaning.
	_Msh_trim_handleCustomChars='_Msh_trim_P=$2
			while str in "${_Msh_trim_P}" "-"; do
				_Msh_trim_P=${_Msh_trim_P%%-*}${_Msh_trim_P#*-}
			done
			eval "$1=\${$1#\"\${$1%%[!\"\$_Msh_trim_P\"-]*}\"}; $1=\${$1%\"\${$1##*[!\"\$_Msh_trim_P\"-]}\"}"
			unset -v _Msh_trim_P'
else
	_Msh_trim_handleCustomChars='eval "$1=\${$1#\"\${$1%%[!\"\$2\"]*}\"}; $1=\${$1%\"\${$1##*[!\"\$2\"]}\"}"'
fi
# Piece it together.
eval 'trim() {
	case ${#},${1-} in
	( [12], | [12],[0123456789]* | [12],*[!"$ASCIIALNUM"_]* )
		die "trim: invalid variable name: $1" ;;
	( 1,* )	eval "$1=\${$1#\"\${$1%%[!'"${_Msh_trim_whitespace}"']*}\"}; $1=\${$1%\"\${$1##*[!'"${_Msh_trim_whitespace}"']}\"}" ;;
	( 2,* )	'"${_Msh_trim_handleCustomChars}"' ;;
	( * )	die "trim: incorrect number of arguments (was $#, should be 1 or 2)" ;;
	esac
}'
unset -v _Msh_trim_whitespace _Msh_trim_handleCustomChars

if thisshellhas ROFUNC; then
	readonly -f trim
fi
