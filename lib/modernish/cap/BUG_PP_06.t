#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PP_06: POSIX says that unquoted $@ initially generates as many
# fields as there are positional parameters, and then (because $@ is
# unquoted) each field is split further according to IFS. With this
# bug, the latter step is not done.
# Found on: zsh < 5.3

set -- ab cdXef gh
push IFS
IFS='X'
set -- $@ $*
pop IFS
case $#,${1-},${2-},${3-},${4-},${5-},${6-},${7-},${8-} in
# expected result:
# 8,ab,cd,ef,gh,ab,cd,ef,gh
( 7,ab,cdXef,gh,ab,cd,ef,gh, )
	;;	# got bug
( * )	return 1 ;;
esac
