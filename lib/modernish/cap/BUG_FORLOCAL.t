#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_FORLOCAL: a 'for' loop in a function makes the iteration variable
# local to the function, so it won't survive the execution of the function
# (even if it existed globally before).
#
# Found on: yash. This is intentional and documented behaviour on yash in
# non-POSIX mode, but in POSIX terms it's a bug, so we mark it as such.
# (Yash in POSIX mode is slow and limited, so we like to be able to run
# modernish without it, which requires compatibility with this bug/feature.)

_Msh_testFn() {
	for _Msh_test in ok; do
		:
	done
}
_Msh_testFn
unset -f _Msh_testFn
case ${_Msh_test+s} in
( '' )	;;
( * )	return 1 ;;
esac
