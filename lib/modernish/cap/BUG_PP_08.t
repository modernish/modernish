#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PP_08: When IFS is null, unquoted $@ and $* do not generate one field
# for each positional parameter as expected, but instead join them into a
# single field.
# Found on: yash < 2.44

set "abc" "def ghi" "jkl"
push IFS
IFS=
set $@
pop IFS
case $#,${1-},${2-},${3-} in
# expected result: "3,abc,def ghi,jkl"
( "1,abcdef ghijkl,," ) ;;	# got bug
( * ) return 1 ;;
esac
