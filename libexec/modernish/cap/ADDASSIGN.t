#! /shell/capability/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# ADDASSIGN: Append a string to a variable using additive assignment VAR+=string
_Msh_test=a
_Msh_ADDASSIGN_PATH=$PATH
PATH=/dev/null
{ _Msh_test+=b; } 2>| /dev/null
PATH=${_Msh_ADDASSIGN_PATH}
unset -v _Msh_ADDASSIGN_PATH
case ${_Msh_test} in
( ab )	;;
( * )	return 1 ;;
esac
