#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PP_04C:  In e.g. : ${var:=$*}, the expansion incorrectly generates
# multiple fields. POSIX says the expansion (before field splitting) shall
# generate the result of the assignment, i.e. 1 field. Workaround: quote
# the expansion. (mksh R50)

push IFS
set -- one "two three" four
IFS=
set -- ${_Msh_test:=$*}
! identic "$#" 1
pop --keepstatus IFS
