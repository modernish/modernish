#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_CMDEXPAN: if the 'command' command results from an expansion, it acts
# like 'command -v', showing the path of the command instead of executing it.
#
# Bug found on: AT&T ksh93

set -- command true
_Msh_test=$(PATH=$DEFPATH; "$@")
case ${_Msh_test} in
( true | */true )
	;;
( * )	return 1 ;;
esac
