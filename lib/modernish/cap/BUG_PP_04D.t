#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PP_04D: When field-splitting the result of an expansion such
# as ${var:=$*}, if the first positional parameter starts with a space,
# an initial empty field is incorrectly generated. (mksh <= R50)

push IFS
set -- " foo "
unset -v IFS
set -- ${_Msh_test:=$*}
str eq "$#,${1-},${2-},${_Msh_test-}" "2,,foo, foo "	# expected: "1,foo,, foo "
pop --keepstatus IFS
