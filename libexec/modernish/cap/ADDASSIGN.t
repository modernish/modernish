#! /shell/capability/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# ADDASSIGN: Append a string to a variable using additive assignment VAR+=string
(	_Msh_test=a
	PATH=/dev/null
	_Msh_test+=b
	case ${_Msh_test} in
	( ab )	;;
	( * )	exit 1 ;;
	esac
) 2>/dev/null || return 1
