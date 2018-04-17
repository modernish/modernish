#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PP_11: If IFS is set and empty (no field separator for $*), assigning
# unquoted $* to a variable (i.e.: foo=$*) causes the fields to be separated
# by a space in the variable, instead of joined together without a separator.
#
# Found on: bash 2.05b, 3.0

set -- a b
push IFS
IFS=
_Msh_test=$*
pop IFS
case "${_Msh_test}" in
( "a b" )
	;;
( * )	return 1 ;;
esac
