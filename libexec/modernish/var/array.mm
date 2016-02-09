#! /module/for/moderni/sh

# TODO: array unset <arrayname>
#	array unset <arrayname>[<element>]
#	array isset <arrayname>
#	array isset <arrayname>[<element>]
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

array() {
	[ $# -eq 1 ] || die "array: incorrect number of arguments (was $#, must be 1)" || return
	case "$1" in

	# Assignment.
	( [abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_]*'['[${ASCIIALNUM}_]*']='* )
		# Parse syntax, splitting the arg in three: array, key, value.
		_Msh_array_V="${1#*=}"
		set -- "${1%%\[*}" "${1#*\[}" 
		set -- "$1" "${2%%]*}"

		# Validate array and key name, enforcing variable naming rules
		# and disallowing the internal separators __A and __K.
		# (The extra "x" in the 'case' argument is to avoid a false
		# negative in case the array name ends in __ and key name
		# starts with A or K, or array name ends in _ and key name
		# starts with _A or _K.)
		case ${1}x${2} in
		( *[!${ASCIIALNUM}_]* | *__[AK]* )
			die "array: invalid variable or key name: $1[$2]" || return ;;
		esac

		eval "_Msh__A${1}__K${2}=\${_Msh_array_V}"
		unset -v _Msh_array_V
		;;

	# Store a key's value in a variable.
	# If the key doesn't exist, unset the variable and returns with status 1.
	( [abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_]*'='[abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_]*'['[${ASCIIALNUM}_]*']' )
		set -- "${1%%\[*}" "${1#*\[}" "${1%%=*}"
		set -- "${1#*=}" "${2%]}" "$3"
		case "${1}x${2}" in
		( *[!${ASCIIALNUM}_]* | *__[AK]* )
			die "array: invalid array or key name: $1[$2]" || return ;;
		esac
		case "$3" in
		( *[!${ASCIIALNUM}_]* )
			die "array: invalid variable name: $3" || return ;;
		esac
		if isset "_Msh__A${1}__K${2}"; then
			eval "${3}=\${_Msh__A${1}__K${2}}"
		else
			unset -v "${3}"
			return 1
		fi
		;;

	# Output a key's value.
	( [abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_]*'['[${ASCIIALNUM}_]*']' )
		set -- "${1%%\[*}" "${1#*\[}"
		set -- "$1" "${2%]}"
		case "${1}x${2}" in
		( *[!${ASCIIALNUM}_]* | *__[AK]* )
			die "array: invalid array or key name: $1[$2]" || return ;;
		esac
		isset "_Msh__A${1}__K${2}" && eval "printf '%s\n' \"\${_Msh__A${1}__K${2}}\""
		;;

	# array arrayname[]
	# Dump an array as shell code that will reproduce it.
	# Sort with -u and check each varname in case a value contains
	# newline followed by a literal _Msh__Aarray__Kkey=
	( [abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_]*'[]' )
		set -- "${1%\[\]}"
		case "$1" in
		( *[!${ASCIIALNUM}_]* | *__[AK]* )
			die "array: invalid array name: $1" || return ;;
		esac
		set \
		| { command -p sed -n "/^_Msh__A${1}__K[${ASCIIALNUM}_]*=/ s/^_Msh__A${1}__K\(.*\)=.*/\1/p" \
			|| die "array: 'sed' failed" || return; } \
		| { command -p sort -u || die "array: 'sort' failed" || return; } \
		| while IFS='' read -r key; do
			if isset "_Msh__A${1}__K$key"; then
				eval "_Msh_array_val=\${_Msh__A${1}__K${key}}"
				shellquote _Msh_array_val || die "array: 'shellquote' failed" || return
				print "array ${1}[${key}]=${_Msh_array_val}"
			fi
		done
		;;
	( * )
		die "array: syntax error" ;;
	esac
}
