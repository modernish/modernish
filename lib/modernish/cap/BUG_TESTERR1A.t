#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_TESTERR1A: AT&T ksh: 'test'/'[' exits with a non-error 'false' status
# (1) if an invalid argument is given to an operator.
PATH=$DEFPATH command test 123 -eq 1XX 2>/dev/null
case $? in
( 1 ) ;;
( * ) return 1 ;;
esac

