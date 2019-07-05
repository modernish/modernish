#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_ARITHSPLT: Unquoted arithmetic expressions
# are not subject to field splitting as expected.
# Bug found in: zsh, pdksh, mksh<=R49

push IFS
IFS=0
set -- $((103))
pop IFS
case ${#},${1-} in
( 1,103 ) ;;
( * )	return 1 ;;
esac
