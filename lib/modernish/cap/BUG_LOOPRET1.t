#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_LOOPRET1: If a 'return' command is given with an exit status argument
# within the set of conditional commands in a 'while' or 'until' loop (i.e.,
# between 'while'/'until' and 'do'), the exit status argument is ignored and
# the function returns with status 0 instead of the specified status.
# Found on: dash <= 0.5.8; zsh <= 5.2

_Msh_testFn() {
	until return 42; do
	#     ^^^^^^^^^ this returns 0 with the bug
		return 13	# should never get here
	done
}

_Msh_testFn
_Msh_test=$?
unset -f _Msh_testFn
case ${_Msh_test} in
( 0 )	return 0 ;;
( * )	return 1 ;;
esac
