#! /shell/capability/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# ARITHCMD: standalone arithmetic evaluation using a command like
# ((expression)). The expression is evaluated using arithmetic as in
# standard $((expression)). If the value of the expression is non‐zero, the
# return status is 0; otherwise the return status is 1. This is exactly
# equivalent to 'let "expression"', but generally much faster.
# Supported by bash, zsh, AT&T ksh, and all pdksh variants.
_Msh_test=35
_Msh_ARITHCMD_PATH=$PATH
PATH=/dev/null				# thwart possible external command called '_Msh_test+=67'
{ ((_Msh_test/=5)); } 2>| /dev/null	# on shells without ARITHCMD, forks subshell and command not found
PATH=${_Msh_ARITHCMD_PATH}
unset -v _Msh_ARITHCMD_PATH
case ${_Msh_test} in
( 7 )	;;
( * )	return 1 ;;
esac
