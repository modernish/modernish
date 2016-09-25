#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_CMDPV: 'command -pv' does not find builtins. ({pd,m}ksh, zsh)
_Msh_cmdPV_PATH=$PATH
PATH=/dev/null
if command -pv : >|/dev/null 2>&1; then
	PATH=${_Msh_cmdPV_PATH}
	unset -v _Msh_cmdPV_PATH
	return 1
else
	PATH=${_Msh_cmdPV_PATH}
	unset -v _Msh_cmdPV_PATH
fi
