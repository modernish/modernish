#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_FNREDIRP: I/O redirections on function definitions are forgotten if the
# function is called as part of a pipeline with at least one '|'. (bash 2.05b)

_Msh_testFn() {
	echo hi 1>&3
} 3>&1

case $(: | _Msh_testFn) in
( hi )	return 1 ;;	# ok
( '' )	return 0 ;;	# bug
( * )	echo "BUG_FNREDIRP: internal error"; return 2 ;;
esac 2>/dev/null

# Workaround: use an extra pair of braces either when defining the
# function or when calling the function. For instance, either:
#	_Msh_testFn() { {
#		echo hi 1>&3
#	} 3>&1; }
# or:
#	case $(: | { _Msh_testFn; }) in
# would cause this bug to remain undetected on bash 2.05b.
