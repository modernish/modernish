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
# TODO: support FLOAT

alias with='_Msh_with_init=y && while _Msh_doWith'

# Since we have full POSIX arithmetics with assignment and comparison, we
# don't need "eval" at all. Avoiding repeated shell grammar parsing while
# using arith to combine the assignment and the comparison is much faster.
_Msh_doWith() {
	case ${_Msh_with_init-} in
	( "${1-},${3-},${5-}" )
		return "$(((${_Msh_with_var}+=_Msh_with_inc)${_Msh_with_cmp}${3}))" ;;
	esac

	case ${_Msh_with_init+s},${#},${2-},${4-},${1-} in
	( s,[35],to,*,=* | s,[35],to,*,[0123456789]*=* | s,[35],to,*,*[!${ASCIIALNUM}_]*=* )
		die "with: invalid variable name: '${1%=*}'" || return ;;
	( s,3,to,,*=* )
		_Msh_with_var=${1%=*}
		isint "${1##*=}" || die "with: assignment: integer value expected, got '${1##*=}'" || return
		isint "$3" || die "with: to: integer value expected, got '$3'" || return
		_Msh_with_inc=$(( ${1##*=} > $3 ? -1 : 1 )) ;;
	( s,5,to,step,*=* )
		_Msh_with_var=${1%=*}
		isint "${1##*=}" || die "with: assignment: integer value expected, got '${1##*=}'" || return
		isint "$3" || die "with: to: integer value expected, got '$3'" || return
		isint "$5" || die "with: step: integer value expected, got '$5'" || return
		_Msh_with_inc=$(($5)) ;;
	( s,[35],to,* )
		die "with: syntax error: assignment expected" || return ;;
	( s,2,to,,* )
		die "with: to: integer value expected" || return ;;
	( s,4,to,step,* )
		die "with: step: integer value expected" || return ;;
	( s,[45],to,* )
		die "with: syntax error: 'step' expected, got '$4'" || return ;;
	( s,?[!,]* | s,[6789],* )
		die "with: syntax error: excess arguments" || return ;;
	( s,?,* )
		die "with: syntax error: 'to' expected${2+, got '$2'}" || return ;;
	( * )
		die "with: init: internal error" || return ;;
	esac

	case ${_Msh_with_inc} in
	( -* )	_Msh_with_cmp='<' ;;
	( * )	_Msh_with_cmp='>' ;;
	esac

	case ${_Msh_with_init} in
	( y )	: "$(($1))" ;;					# loop init
	( * )	: "$((${_Msh_with_var}+=_Msh_with_inc))" ;;	# loop re-entry
	esac

	_Msh_with_init=$1,$3,${5-}

	return "$((${_Msh_with_var}${_Msh_with_cmp}${3}))"
}
