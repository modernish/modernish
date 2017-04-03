#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PP_04: Assigning the positional parameters to a variable using
# a conditional assignment within a parameter substitution, such as
# : ${var=$*}, discards everything but the last field if IFS is empty.
# (pdksh, mksh)
#
# Note: an easy way to circumvent this bug is to always quote either the
# $* within the expansion or the expansion as a whole, i.e.: ${var="$*"}
# or "${var=$*}". This works correctly on all shells known to run modernish.
#
# See also BUG_PP_04_S (assignment is correct but expansion is wrongly split).

set -- one 'two three' four
push IFS
IFS=''
: ${_Msh_test=$*}
identic "${_Msh_test}" 'four'
pop --keepstatus IFS
