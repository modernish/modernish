#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PSUBIFSWH: When field-splitting unquoted parameter substitutions like
# ${var#foo}, ${var##foo}, ${var%foo} or ${var%%foo} on whitespace
# IFS, if there is an initial empty field, a spurious extra initial empty
# field is generated.
#
# Bug found on: mksh <= R48b
# Ref.: https://www.mail-archive.com/miros-mksh@mirbsd.org/msg01017.html

_Msh_test="foo one two"
push IFS
IFS=" "
set -- ${_Msh_test#foo}
pop IFS
case ${#},${1-},${2-},${3-} in
# expected: 2,one,two,
( 3,,one,two ) ;;
( * ) return 1 ;;
esac
