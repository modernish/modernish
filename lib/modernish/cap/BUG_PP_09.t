#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PP_09: When IFS is set, non-empty but does not contain a space,
# unquoted $* within a substitution (e.g. ${1+$*} or ${var-$*}) does
# not generate one field for each positional parameter as expected,
# but instead joins them into a single field separated by spaces
# (even though, as said, IFS does not contain a space).
# Found on: bash 2.05b, 4.3

set "abc" "def ghi" "jkl"
push IFS
IFS=X${CCt}${CCn}
set ${1+$*}
pop IFS
case $#,${1-},${2-},${3-} in
# expected result: "3,abc,def ghi,jkl"
( "1,abc def ghi jkl,," ) ;;	# got bug
( * ) return 1 ;;
esac
