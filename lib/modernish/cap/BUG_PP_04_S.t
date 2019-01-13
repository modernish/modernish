#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PP_04_S: When IFS is null (empty), the result of a substitution
# containing an default assignment to unquoted $* or $@ is incorrectly
# field-split on spaces (no field splitting should occur with null IFS).
#
# Found on: bash 4.2, 4.3
#
# This bug is related to BUG_PP_04, which also tests ${var=$*}, but in that
# bug, the expansion incorrectly generates multiple fields without
# splitting, corrupting the scalar assignment in the process. In BUG_PP_04_S,
# the scalar assignment is executed correctly and fields are generated
# correctly, but the result is split incorrectly.

set -- one 'two three' four
push IFS
IFS=
set -- ${_Msh_test=$*}
pop IFS
str eq "${_Msh_test},${#},${1-},${2-}" "onetwo threefour,2,onetwo,threefour"
