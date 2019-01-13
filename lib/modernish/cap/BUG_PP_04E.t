#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PP_04E: When assigning the positional parameters ($*) to a variable
# using a conditional assignment within a parameter substitution (e.g.: :
# ${var:=$*}, the fields are always joined and separated by spaces, if IFS
# is unset or non-empty, but not if it's set and empty. (They should be
# separated by the first character of IFS instead, or no separator if IFS is
# empty.)
# Bug found on: bash 4.3.

set -- one "two three" four
push IFS
IFS=XYZ
: ${_Msh_test:=$*}
_Msh_test2=${_Msh_test}
_Msh_test=
IFS=
: ${_Msh_test:=$*}
_Msh_test=${_Msh_test2}/${_Msh_test}
pop IFS
unset -v _Msh_test2
str eq "${_Msh_test}" "one two three four/onetwo threefour"
