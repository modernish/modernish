#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_SPCBILOC: Variable assignments preceding special builtins create a
# partially function-local variable if a variable by the same name already
# exists in the parent scope. (bash < 5.0 in POSIX mode)
# Chet Ramey writes: "It creates a variable that claims to be at the global
# scope (context == 0, internally), but is placed in the wrong variable
# table. This is the bug. It manifests itself in different ways."
# Ref.: https://lists.gnu.org/archive/html/bug-bash/2018-05/msg00015.html

_Msh_testFn() {
	_Msh_test=2 :
	unset -v _Msh_test  # needed to reveal global scope on bash 4.2-4.4
}
_Msh_test=1
_Msh_testFn
unset -f _Msh_testFn
case ${_Msh_test-} in
( 1 )	unset -v _Msh_test ;;
( * )	unset -v _Msh_test; return 1 ;;
esac
