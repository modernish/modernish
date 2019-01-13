#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PP_04: Assigning the positional parameters to a variable using
# a conditional assignment within a parameter substitution, such as
# : ${var=$*} or : ${var:=$*}, if IFS is empty:
# 1. in the assignment, discards everything but the last field.
# 2. in the expansion, incorrectly generates multiple fields.
# (pdksh, mksh)
#
# Ref.: https://www.mail-archive.com/miros-mksh@mirbsd.org/msg00680.html
#
# Note: an easy way to circumvent this bug is to always quote either the
# $* within the expansion or the expansion as a whole, i.e.: ${var="$*"}
# or "${var=$*}". This works correctly on all shells known to run modernish.
#
# See also BUG_PP_04_S (assignment is correct but expansion is wrongly split).

set -- one 'two three' four
push IFS
IFS=''
set -- ${_Msh_test:=$*}
pop IFS
str eq "${_Msh_test}" 'four' && ! str eq "$#" 1
