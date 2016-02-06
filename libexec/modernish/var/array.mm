#! /module/for/moderni/sh

# TODO: array unset <arrayname>
#	array unset <arrayname>[<element>]
#	array isset <arrayname>
#	array isset <arrayname>[<element>]

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
		case "${1}x${2}" in
		( *[!${ASCIIALNUM}_]* | *__[AK]* )
			die "array: invalid variable or key name: $1[$2]" || return ;;
		esac

		# For the final variable assignment in 'eval' to work for
		# all possible values, we have to shell-quote the value.
		shellquote _Msh_array_V
		eval "_Msh__A${1}__K${2}=${_Msh_array_V}"
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
		eval "if [ -n \"\${_Msh__A${1}__K${2}+s}\" ]; then ${3}=\"\$_Msh__A${1}__K${2}\"; else unset -v ${3}; return 1; fi"
		;;

	# Output a key's value.
	( [abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_]*'['[${ASCIIALNUM}_]*']' )
		set -- "${1%%\[*}" "${1#*\[}"
		set -- "$1" "${2%]}"
		case "${1}x${2}" in
		( *[!${ASCIIALNUM}_]* | *__[AK]* )
			die "array: invalid array or key name: $1[$2]" || return ;;
		esac
		eval "[ -n \"\${_Msh__A${1}__K${2}+s}\" ] && printf '%s\n' \"\$_Msh__A${1}__K${2}\""
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
		| { command sed -En "/^_Msh__A${1}__K[${ASCIIALNUM}_]+=/ { s/.*__K(.*)=.*/\1/; p; }" \
			|| die "array: 'sed' failed" || return; } \
		| { command sort -u || die "array: 'sort' failed" || return; } \
		| while IFS='' read -r key; do
			if isset _Msh__A${1}__K$key; then
				eval "_Msh_array_val=\"\${_Msh__A${1}__K${key}}\""
				shellquote _Msh_array_val || die "array: 'shellquote' failed" || return
				print "array ${1}[${key}]=${_Msh_array_val}"
			fi
		done
		;;
	( * )
		die "array: syntax error" ;;
	esac
}
