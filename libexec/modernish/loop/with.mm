#! /module/for/moderni/sh
# An alias + internal function pair for a MS BASIC-style 'for' loop, renamed
# a 'with' loop because we can't overload the reserved shell keyword 'for'.
# Integer arithmetic only.
# Usage:
# with <varname>=<value> to <limit> [ step <increment> ]; do
#	<commands>
# done
#
# TODO: when floating point arith is implemented, upgrade 'with' to support it.
#
# FIXED: code injection vuln:
#  y=2; with i=15 to 25 step $y; do [ $i -gt 20 ] && y='25))"; print "code injection"; #'; print $i; done
# FIXED: code injection vuln;
#  y=i; with $y=15 to 25 step 2; do [ $i -ge 20 ] && print=1 && y='print "code injection" #'; print $i; done

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
			isint "${1#*=}" || die "with: assignment: integer value expected, got '${1#*=}'" || return
			eval "$1"
			;;
		( * )
			die "with: syntax error: assignment expected" || return
			;;
		esac
		[ "${2:-}" = 'to' ] || die "with: syntax error: 'to' expected${2:+, got '$2'}" || return
		isint "${3:-}" || die "with: to: integer value expected" || return
		if [ $# -gt 5 ]; then
			die "with: syntax error: excess arguments" || return
		elif [ $# -ge 4 ]; then
			[ "$4" = 'step' ] || die "with: 'step' expected, got '$4'" || return
			isint "${5:-}" || die "with: step: integer value expected${5:+, got '$5'}" || return
		fi
		unset -v _Msh_with_init
	else
		case "${1%%=*}" in
		( '' | [!a-zA-Z_]* | *[!a-zA-Z0-9_]* )
			die "with: invalid variable name: ${1%%=*}" || return ;;
		esac
		eval "${1%%=*}=\"\$((${1%%=*}+\${5:-1}))\"" || die 'with: loop iteration: addition failed' || return
	fi
	if [ "${5:-1}" -ge 0 ]; then
		eval "[ \"\$${1%%=*}\" -le \"\$3\" ]"
	else
		eval "[ \"\$${1%%=*}\" -ge \"\$3\" ]"
	fi && return
	[ $? -gt 1 ] && die "with: end-of-loop check: '[' failed"
}
