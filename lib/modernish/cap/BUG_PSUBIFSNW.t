#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PSUBIFSNW: When field-splitting unquoted parameter substitutions like
# ${var#foo}, ${var##foo}, ${var%foo} or ${var%%foo} on non-whitespace
# IFS, if there is an initial empty field, a spurious extra initial empty
# field is generated.
#
# Bug found on: mksh
# Ref.: https://www.mail-archive.com/miros-mksh@mirbsd.org/msg01017.html

_Msh_test="fooXoneXtwo"
push IFS
IFS=X
set -- ${_Msh_test#foo}
pop IFS
case ${#},${1-},${2-},${3-},${4-} in
# expected: 3,,one,two,
( 4,,,one,two ) ;;
( * ) return 1 ;;
esac
