#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PP_06A: POSIX says that unquoted $@ and $* initially generate as many
# fields as there are positional parameters, and then (because $@ or $* is
# unquoted) each field is split further according to IFS. With this
# bug, the latter step is not done if IFS is unset (i.e. default split).
# Found on: zsh < 5.4

set -- ab 'cd ef' gh
push IFS
unset -v IFS
set -- $@ $*
pop IFS
case $#,${1-},${2-},${3-},${4-},${5-},${6-},${7-},${8-} in
# expected result:
# 8,ab,cd,ef,gh,ab,cd,ef,gh
( 6,ab,cd\ ef,gh,ab,cd\ ef,gh,, )
	;;	# got bug
( * )	return 1 ;;
esac
