#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_NOOCTAL: Shell arithmetic does interpret numbers with leading
# zeroes as octal numbers; these are interpreted as decimal instead,
# though POSIX specifies octal. (older mksh, 2013-ish versions)

case $((010)) in
( 10 )	;;
( * )	return 1 ;;
esac
