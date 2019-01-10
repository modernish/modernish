#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PP_1ARG: When IFS is empty on bash <= 4.3 (i.e. field
# splitting is off), ${1+"$@"} or "${1+$@}" is counted as a single
# argument instead of each positional parameter as separate arguments.
# This also applies to prepending text only if there are positional
# parameters with something like "${1+foobar $@}".
set -- "   \on\e" "\tw'o" " \th\'re\e" " \\'fo\u\r "
push IFS
IFS=''
set -- ${1+"$@"}
pop IFS
case $# in
( 1 )	;;
( * )	return 1 ;;
esac
