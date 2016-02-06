#! /module/for/moderni/sh

# var/string
# String manipulation functions.


# trim: Strip whitespace (or other characters) from the beginning and end of
# a variable's value. Whitespace is defined by the 'space' character class
# (in the POSIX locale, this is tab, newline, vertical tab, form feed,
# carriage return, and space, but in other locales it may be different).
# Optionally, a string of literal characters to trim can be provided in the
# second argument; any of those characters will be trimmed from the beginning
# and end of the variable's value.
# Usage: trim <varname> [ <characters> ]
# TODO: options -l and -r for trimming on the left or right only.
trim() {
	case $# in
	( 1 )	_Msh_trim_C='[:space:]' ;;
	( 2 )	_Msh_trim_C=$2; shellquote -f _Msh_trim_C ;;
	( * )	die "trim: incorrect number of arguments (was $#, should be 1 or 2)" ;;
	esac
	isvarname "$1" || die "trim: invalid variable name: $1" || return
	eval "$1=\${$1#\"\${$1%%[!${_Msh_trim_C}]*}\"}; $1=\${$1%\"\${$1##*[!${_Msh_trim_C}]}\"}"
	unset -v _Msh_trim_C
}

