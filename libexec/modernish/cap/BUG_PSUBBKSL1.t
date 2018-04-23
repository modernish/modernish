#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PSUBBKSL1 (bash 2 & 3, standard dash, Busybox ash)
# A backslash-escaped '}' character within a quoted parameter substitution is
# not unescaped.
_Msh_test=somevalue
case "${_Msh_test+\}}" in
( '\}' ) ;;
( * )	return 1 ;;
esac
