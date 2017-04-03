#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PP_04B: When assigning the positional parameters ($*) to a variable
# using a conditional assignment within a parameter substitution (e.g.:
# : ${var:-$*}, the fields are always joined and separated by spaces,
# regardless of the content of IFS. (They should be separated by the first
# character of IFS instead, or no separator if IFS is empty.)
# Bug found on: bash 2.05b.

set -- one "two three" four
push IFS
IFS=XYZ
: ${_Msh_test:=$*}
pop IFS
identic "${_Msh_test}" "one two three four"
