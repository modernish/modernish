#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_TESTERR0: mksh: 'test'/'[' exits successfully (exit status 0) if
# an invalid argument is given to an operator. (mksh R52 fixes this)
PATH=$DEFPATH command test 123 -eq 1XX 2>/dev/null
case $? in
( 0 ) ;;
( * ) return 1 ;;
esac
