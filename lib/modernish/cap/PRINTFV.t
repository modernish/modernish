#! /shell/capability/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# PRINTFV: shell has a 'printf' builtin that can write to shell variables
# using the -v option.

thisshellhas --bi=printf || return 1
_Msh_test=
command printf -v _Msh_test 'ok\n\n' >/dev/null 2>&1
case ${_Msh_test} in
( "ok$CCn$CCn" ) ;;
( * ) return 1 ;;
esac
