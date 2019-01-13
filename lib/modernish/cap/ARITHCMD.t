#! /shell/capability/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# ARITHCMD: standalone arithmetic evaluation using a command like
# ((expression)). The expression is evaluated using arithmetic as in
# standard $((expression)). If the value of the expression is non‐zero, the
# return status is 0; otherwise the return status is 1. This is exactly
# equivalent to 'let "expression"', but generally much faster.
# Supported by bash, zsh, AT&T ksh, and all pdksh variants.
_Msh_test=35
( command eval '(( _Msh_test /= (5) ))' ) 2>/dev/null && eval '(( _Msh_test /= (5) ))'
case ${_Msh_test} in
( 7 )	;;
( * )	return 1 ;;
esac
