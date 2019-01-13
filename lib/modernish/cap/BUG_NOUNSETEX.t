#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_NOUNSETEX: Cannot assign export attribute to variables in an unset
# state; exporting a variable immediately sets it to the empty value.
export _Msh_test
case ${_Msh_test+s} in
( s )	;;
( * )	return 1 ;;
esac
