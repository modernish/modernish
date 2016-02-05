#! /module/for/moderni/sh
# An alias + internal function pair for a MS BASIC-style 'for' loop, renamed
# a 'with' loop because we can't overload the reserved shell keyword 'for'.
# Integer arithmetic only.
# Usage:
# with <varname>=<value> to <limit> [ step <increment> ]; do
#	<commands>
# done
#
# TODO: when float is implemented, upgrade with to support it.

# The alias can work because aliases are expanded even before shell keywords
# like 'while' are parsed.
alias with='_Msh_with_init=y && while _Msh_doWith'

# Main internal function. Not for direct use.
_Msh_doWith() {
	if [ -n "${_Msh_with_init+y}" ]; then
		case "${1:-}" in
		( *=* )
			case "${1%%=*}" in
			( '' | [!a-zA-Z_]* | *[!a-zA-Z0-9_]* )
				die "with: invalid variable name: ${1%%=*}" || return ;;
			esac
			isint "${1#*=}" || die "with: assignment: integer value expected" || return
			eval "$1"
			;;
		( * )
			die "with: assignment expected" || return
			;;
		esac
		[ "${2:-}" = 'to' ] || die "with: 'to' expected" || return
		isint "${3:-}" || die "with: to: integer value expected" || return
		if [ $# -ge 4 ]; then
			case "${4:-}" in
			( step )
				isint "${5:-}" || die "with: step: integer value expected" || return
				;;
			( * )
				die "with: 'step' expected" || return
				;;
			esac
		fi
		if [ $# -gt 5 ]; then
			die "with: syntax error: excess arguments" || return
		fi
		unset -v _Msh_with_init
	else
		eval "${1%%=*}=\$((${1%%=*}+${5:-1}))"
	fi
	if [ ${5:-1} -ge 0 ]; then
		eval "[ \$${1%%=*} -le $3 ]"
	else
		eval "[ \$${1%%=*} -ge $3 ]"
	fi
}
