#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PSUBEMIFS: if IFS is empty (no split, as in safe mode), then if a
# parameter substitution of the forms
#	${foo-$*} ${foo+$*} ${foo:-$*} ${foo:+$*}
# occurs in a command argument, the characters $CC01 (^A) or $CC7F (DEL) are
# stripped from the expanded argument.
#
# Bug found on: bash 4.4

_Msh_test=$CC01$CC02$CC03$CC7F
set "abc" "def ghi" "$_Msh_test"
push IFS
IFS=
set ${_Msh_test:+$*}
pop IFS
str eq "${#},${1}" "1,abcdef ghi$CC02$CC03"
