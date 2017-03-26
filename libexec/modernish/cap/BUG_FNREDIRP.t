#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_FNREDIRP: I/O redirections on function definitions are forgotten if the
# function is called as part of a pipeline with at least one '|'. (bash 2.05b)
#
# Workaround: use an extra pair of braces either when defining the
# function or when calling the function. For instance, either:
#	_Msh_testFn() { {
#		echo hi
#	} >/dev/null; }
# or:
#	case $(: | { _Msh_testFn; }) in
# would cause this bug to remain undetected on bash 2.05b.

_Msh_testFn() {
	echo bug
} >/dev/null

case $(: | _Msh_testFn) in
( '' )	unset -f _Msh_testFn; return 1 ;;
( bug )	unset -f _Msh_testFn; return 0 ;;
( * )	echo "BUG_FNREDIRP: internal error"; return 2 ;;
esac
