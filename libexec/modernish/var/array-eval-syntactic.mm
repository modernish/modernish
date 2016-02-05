#!/bin/sh

array() {
	case "$1" in

	# Assignment.
	( *'['*']='* )
		# Parse syntax, splitting the arg in three: array, key, value.
		set -- "${1%%\[*}" "${1#*\[}" "${1#*=}"
		set -- "$1" "${2%%]*}" "$3"

		# Validate array and key name, enforcing variable naming rules
		# and disallowing the internal separators __A and __K.
		# (The extra "x" in the 'case' argument is to avoid a false
		# negative in case the array name ends in __ and key name
		# starts with A or K, or array name ends in _ and key name
		# starts with _A or _K.)
		case "${1}x${2}" in
		( '' | [!a-zA-Z_]* | *[!a-zA-Z0-9_]* | *__[AK]* )
			die "array: invalid variable or key name: $1[$2]" ;;
		esac

		# For the final variable assignment to work for all possible
		# values, we have to enclose the value in single quotes, and
		# escape any single quotes in the value itself, changing
		# every ' to '\'' . That backslash needs to be doubled up
		# twice: once for the double-quotes in the "sed" call
		# itself, and once for "eval".
		# We also have to work around two other problems:
		#   1.  'sed' adds a linefeed if there isn't one;
		#   2.  $(command substitution) strips ALL final linefeeds.
		# Thwart both of these using a final x + LF.
		case "$3" in
		( *\'* )
			# TODO: to avoid subshells and workarounds,
			# use 'replaceallin' when it's debugged.
			set -- "$1" "$2" "$(printf '%s\n' "${3}x" | sed "s/'/'\\\\''/g")"
			set -- "$1" "$2" "${3%x}"  # remove final x; linefeeds preserved
			;;
		esac
		# Hopefully everything is now validated/sanitized. The dangerous bit:
		eval "_msh__A${1}__K${2}='${3}'"
		;;

	# Retrieve a key's value, storing it in a variable.
	( *'='*'['*']' )
		set -- "${1%%\[*}" "${1#*\[}" "${1%%=*}"
		set -- "${1#*=}" "${2%]}" "$3"
		case "${1}x${2}" in
		( '' | [!a-zA-Z_]* | *[!a-zA-Z0-9_]* | *__[AK]* )
			die "array: invalid array or key name: $1[$2]" ;;
		esac
		case "$3" in
		( '' | [!a-zA-Z_]* | *[!a-zA-Z0-9_]* )
			die "array: invalid variable name: $3" ;;
		esac
		eval "${3}=\"\$_msh__A${1}__K${2}\""
		;;

	# Output a key's value.
	( *'['*']' )
		set -- "${1%%\[*}" "${1#*\[}"
		set -- "$1" "${2%]}"
		case "${1}x${2}" in
		( '' | [!a-zA-Z_]* | *[!a-zA-Z0-9_]* | *__[AK]* )
			die "array: invalid array or key name: $1[$2]" ;;
		esac
		eval "VAL=\"\$_msh__A${1}__K${2}\""
		;;

	# List keys.
	# TODO: what if a value contains newline followed by a literal _msh__Akey__Kvalue=?
	( * )
		case "$1" in
		( '' | [!a-zA-Z_]* | *[!a-zA-Z0-9_]* | *__[AK]* )
			die "array: invalid array name: $1" ;;
		esac
#		set | sed -n "/^_msh__A${1}__K[a-zA-Z0-9_][a-zA-Z0-9_]*=/ { s/.*__K\(.*\)=.*/\1/; p; }"
		set | sed -en "/^_msh__A${1}__K[a-zA-Z0-9_]+=/ { s/.*__K(.*)=.*/\1/; p; }"
		;;
	esac
}
