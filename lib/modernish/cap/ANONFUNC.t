#! /shell/capability/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# ANONFUNC: zsh anonymous functions
( eval '_Msh_test=

	() {
		_Msh_test=$1
	} anon

	case ${_Msh_test} in
	( anon ) ;;
	( * ) \exit 1 ;;
	esac'
) 2>/dev/null || return 1
