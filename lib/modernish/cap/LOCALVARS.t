#! /shell/capability/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.
#
# LOCALVARS: Function-local variables using 'local' (either
# as a builtin, or as an alias for 'typeset' set by modernish
# initialisation) in functions defined using POSIX syntax().

unset -f local	# just to be sure
PATH=/dev/null command -v local >/dev/null || return 1

_Msh_testFn() {
	local _Msh_test=LOCAL 2>/dev/null || return
	case ${_Msh_test} in
	( LOCAL ) ;;
	( * ) return 1 ;;
	esac
}

_Msh_test=GLOBAL
_Msh_testFn || { unset -f _Msh_testFn; return 1; }
unset -f _Msh_testFn
case ${_Msh_test} in
( GLOBAL ) ;;
( * ) return 1 ;;
esac
