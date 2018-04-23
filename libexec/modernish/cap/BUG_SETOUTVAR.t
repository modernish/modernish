#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_SETOUTVAR: The 'set' builtin only outputs native function-local
# variables when called from a shell function. (found in yash)
# Ref.: https://osdn.net/projects/yash/ticket/38181

_Msh_test=foo
_Msh_testFn() {
	set
}

case $(_Msh_testFn) in
( '' )	unset -f _Msh_testFn ;;
( * )	unset -f _Msh_testFn; return 1 ;;
esac
