#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PP_07: unquoted $* and $@ (incl. in substitutions like ${1+$@}
# or ${var-$*}) do not perform default field splitting if IFS is unset.
# Found on: zsh (up to 5.3.1) in sh mode

set -- ab 'cd ef' gh
push IFS
unset -v IFS
set -- $* $@
pop IFS
case $#,${1-},${2-},${3-},${4-},${5-},${6-},${7-},${8-} in
# expected result:
# "8,ab,cd,ef,gh,ab,cd,ef,gh"
( "6,ab,cd ef,gh,ab,cd ef,gh,," ) ;;	# got bug
( * )	return 1 ;;
esac
