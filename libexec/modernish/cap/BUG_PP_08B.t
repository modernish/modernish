#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PP_08B: When IFS is null, unquoted $* within a substitution (e.g.
# ${1+$*} or ${var-$*}) does not generate one field for each positional
# parameter as expected, but instead joins them into a single field.
# Found on: bash 3 and 4

set "abc" "def ghi" "jkl"
push IFS
IFS=
set ${1+$*}
pop IFS
case $#,${1-},${2-},${3-} in
# expected result: "3,abc,def ghi,jkl"
( "1,abcdef ghijkl,," ) ;;	# got bug
( "1,abc def ghi jkl,," ) ;;	# got bug (pdksh, FTL_PARONEARG)
( * ) return 1 ;;
esac
