#!/bin/sh

array() {
	case "$1" in

	# Assignment.
	( *'['*']='* )
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
		case "${1}x${2}" in
		( '' | [!a-zA-Z_]* | *[!a-zA-Z0-9_]* | *__[AK]* )
			die "array: invalid variable or key name: $1[$2]" || return ;;
		esac

		# For the final variable assignment in 'eval' to work for
		# all possible values, we have to shell-quote the value.
		quotevar _Msh_array_V
		eval "_Msh__A${1}__K${2}='${_Msh_array_V}'"
		unset _Msh_array_V
		;;

	# Retrieve a key's value, storing it in a variable.
	( *'='*'['*']' )
		set -- "${1%%\[*}" "${1#*\[}" "${1%%=*}"
		set -- "${1#*=}" "${2%]}" "$3"
		case "${1}x${2}" in
		( '' | [!a-zA-Z_]* | *[!a-zA-Z0-9_]* | *__[AK]* )
			die "array: invalid array or key name: $1[$2]" || return ;;
		esac
		case "$3" in
		( '' | [!a-zA-Z_]* | *[!a-zA-Z0-9_]* )
			die "array: invalid variable name: $3" || return ;;
		esac
		eval "${3}=\"\$_Msh__A${1}__K${2}\""
		;;

	# Output a key's value.
	( *'['*']' )
		set -- "${1%%\[*}" "${1#*\[}"
		set -- "$1" "${2%]}"
		case "${1}x${2}" in
		( '' | [!a-zA-Z_]* | *[!a-zA-Z0-9_]* | *__[AK]* )
			die "array: invalid array or key name: $1[$2]" || return ;;
		esac
		eval "VAL=\"\$_Msh__A${1}__K${2}\""
		;;

	# List keys.
	# TODO: what if a value contains newline followed by a literal _Msh__Aarray__Kkey=?
	( * )
		case "$1" in
		( '' | [!a-zA-Z_]* | *[!a-zA-Z0-9_]* | *__[AK]* )
			die "array: invalid array name: $1" || return ;;
		esac
		# TODO: use 'readc' if it's ever fixed to be compatible with parallel execution.
		set | sed -en "/^_Msh__A${1}__K[a-zA-Z0-9_]+=/ { s/.*__K(.*)=.*/\1/; p; }"
		;;
	esac
}
