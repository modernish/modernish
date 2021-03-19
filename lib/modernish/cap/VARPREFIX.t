#! /shell/capability/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.
#
# VARPREFIX: The expansions ${!prefix@} and ${!prefix*} yield the names
# of set variables whose names begin with 'prefix', in the same way and
# with the same quoting effects as $@ and $*, respectively. (bash, ksh93)
#
# NOTE: on bash, the expansion will include the 'prefix' variable itself,
# whereas on ksh93, it will not. This has been fixed on ksh 93u+m 2021-03-09.
# See: https://github.com/ksh93/ksh/issues/183
# (TODO: remove this note when we stop supporting BUG_VARPREFIX/ksh 93u+)

( eval ': ${!_Msh_test@} ${!_Msh_test*}' ) 2>/dev/null || return 1
_Msh_test_3=bad
eval 'command unset -v "${!_Msh_test@}"'
_Msh_test_1=o _Msh_test_2=k
push IFS
IFS=/
eval 'set -- "${!_Msh_test_@}"; _Msh_test=/$*/${!_Msh_test_*}/'
pop IFS
unset -v _Msh_test_1 _Msh_test_2 _Msh_test_3
str eq "${_Msh_test}" /_Msh_test_1/_Msh_test_2/_Msh_test_1/_Msh_test_2/
