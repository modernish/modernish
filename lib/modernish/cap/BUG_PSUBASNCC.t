#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PSUBASNCC: in an assignment parameter substitution of the form
#	${foo=value}
# if the characters $CC01 (^A) or $CC7F (DEL) are present in the value, all
# their occurrences are stripped from the expansion (although the assignment
# itself is done correctly). If the expansion is quoted, only $CC01 is
# stripped. This is regardless of the state of IFS.
# Exception: if IFS is null, the assignment in ${foo=$*} (unquoted) is
# buggy too: it strips ^A from the assigned value.
#
# Bug found on: bash 4.2, 4.3, 4.4

set -- ${_Msh_test=ab$CC01$CC02$CC7F}
unset -v _Msh_test
set -- "$@" "${_Msh_test=ab$CC01$CC02$CC7F}"
str eq "${_Msh_test},$1,$2" "ab$CC01$CC02${CC7F},ab$CC02,ab$CC02$CC7F"
