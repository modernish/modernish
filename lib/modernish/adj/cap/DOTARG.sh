#! /shell/capability/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# Helper script for lib/modernish/cap/DOTARG.t; see there for info

unset -v _Msh_test
case "$#,${1-},${2-}" in
( 2,one,two )	return 0 ;;
( 0,, )		return 1 ;;
( * )		putln "DOTARG: internal error ($#,${1-}.${2-})"
		return 2 ;;
esac
