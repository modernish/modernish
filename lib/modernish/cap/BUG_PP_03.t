#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PP_03: Assigning var=$* only assigns the first field, failing to
# join and discarding the rest of the fields, if IFS is either empty
# or unset (zsh 5.3.1) or if IFS is empty (pdksh/mksh).

set -- one 'two three' four
push IFS
IFS=''
_Msh_test=$*
str eq "${_Msh_test}" 'one'
pop --keepstatus IFS
