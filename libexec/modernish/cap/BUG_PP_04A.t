#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PP_04A: When IFS is unset, conditional assignments of unquoted $* to
# a variable within a parameter substitution, e.g. ${var=$*} or ${var:=$*},
# removes leading and trailing spaces (but not tabs or newlines).
# Without this bug, neither IFS nor quoting makes any difference when
# performing a shell variable assignment.
# Bug found on: bash 2.05b through 4.4.
# Ref.: https://lists.gnu.org/archive/html/bug-bash/2017-04/msg00001.html

set "  abc  " " def  ghi " "jkl "
push IFS
unset -v IFS
: ${_Msh_test:=$*/$*/${_Msh_test-$*}/${_Msh_test-$*}}
pop IFS
case ${_Msh_test} in
# expected result:
# '  abc    def  ghi  jkl /  abc    def  ghi  jkl /  abc    def  ghi  jkl /  abc    def  ghi  jkl '
( 'abc def ghi jkl / abc def ghi jkl /abc def ghi jkl/abc def ghi jkl' )
	return 0 ;;	# bug
( * )	return 1 ;;
esac
