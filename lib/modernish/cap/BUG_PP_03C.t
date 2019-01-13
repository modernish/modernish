#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PP_03C: Assigning var=${var-$*} only assigns the first field, failing
# to join and discarding the rest of the fields, if var is unset and IFS is
# unset (zsh 5.3, 5.3.1).

set -- one 'two three' four
push IFS
unset -v IFS
_Msh_test=${_Msh_test-$*}
str eq "${_Msh_test}" 'one'
pop --keepstatus IFS
