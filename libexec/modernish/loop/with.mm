#! /module/for/moderni/sh
# An alias + internal function pair for a MS BASIC-style 'for' loop, renamed
# a 'with' loop because we can't overload the reserved shell keyword 'for'.
# Integer arithmetic only.
#
# Usage:
# with <varname>=<value> to <limit> [ step <increment> ]; do
#	<commands>
# done
#
# Default for <increment> is 1 if <limit> is greater than or equal to
# <value>, or -1 if <limit> is less than <value>. (The latter is different
# from the original BASIC 'for' loop where the default is always 1.)
#
# BUG:	'with' is not a true shell keyword, but an alias for two commands.
#	This makes it impossible to pipe data directly into a 'with' loop as
#	you would with native 'for', 'while' and 'until'.
#	Workaround: enclose the entire loop in { braces; }, for example:
#	cat file | { with i=1 to 5; do read L; print "$i: $L"; done; }
#
# TODO? A different syntax with two aliases, like with 'setlocal'...'endlocal',
#	would make a true shell block possible, but would require abandoning
#	the usual do ... done syntax. Is this preferable?
#
# TODO? Allow/ignore blanks in values, so the output of something
#	like 'wc -c' can be used directly.

alias with='_Msh_with_init=y && while _Msh_doWith'

# Since we have full POSIX arithmetics with assignment and comparison, we
# don't need "eval" at all. Avoiding repeated shell grammar parsing while
# using arith to combine the assignment and the comparison is much faster.
_Msh_doWith() {
	if [ "X${_Msh_with_init-}" != "X${1-},${3-},${5-}" ]; then
		if [ -z "${_Msh_with_init+s}" ]; then
			die "with: init failed" || return
		fi
		if [ "$#" -gt 5 ]; then
			die "with: syntax error: excess arguments" || return
		fi
		case "${1-}" in
		( *=* )
			_Msh_with_var="${1%%=*}"
			case "${_Msh_with_var}" in
			( '' | [0123456789]* | *[!${ASCIIALNUM}_]* )
				die "with: invalid variable name: ${_Msh_with_var}" || return ;;
			esac
			isint "${1#*=}" || die "with: assignment: integer value expected, got '${1#*=}'" || return
			;;
		( * )
			die "with: syntax error: assignment expected" || return
			;;
		esac
		[ "X${2-}" = 'Xto' ] || die "with: syntax error: 'to' expected${2:+, got '$2'}" || return
		isint "${3-}" || die "with: to: integer value expected${3:+, got '$3'}" || return
		if [ "$#" -ge 4 ]; then
			[ "X$4" = 'Xstep' ] || die "with: 'step' expected, got '$4'" || return
			isint "${5-}" || die "with: step: integer value expected${5:+, got '$5'}" || return
			_Msh_with_inc="$5"
		elif [ "${1#*=}" -gt "$3" ]; then
			_Msh_with_inc=-1
		else
			_Msh_with_inc=1
		fi
		if [ "${_Msh_with_inc}" -ge 0 ]; then
			_Msh_with_cmp='>'
		else
			_Msh_with_cmp='<'
		fi
		if [ "X${_Msh_with_init}" = 'Xy' ]; then
			: "$(($1))" || die "with: loop init: assignment failed" || return
		else
			: "$((${_Msh_with_var}=${_Msh_with_var}+_Msh_with_inc))" \
			|| die 'with: loop re-entry: addition failed' || return
		fi
		_Msh_with_init="$1,$3,${5-}"
		return "$((${_Msh_with_var}${_Msh_with_cmp}${3}))"
	fi
	return "$(((${_Msh_with_var}=${_Msh_with_var}+_Msh_with_inc)${_Msh_with_cmp}${3}))"
}
