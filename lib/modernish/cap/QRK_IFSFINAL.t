#! /shell/quirk/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# QRK_IFSFINAL: in field splitting, a final non-whitespace IFS delimiter
# character is counted as an empty field (yash < 2.42, zsh, pdksh). Modernish
# designates this a QRK (quirk), not a BUG, because POSIX is ambiguous on
# this, and it's really not clear that the behaviour is undesirable.
# Nonetheless it seems the dominant interpretation considers it a bug.
# Ref.: http://www.open-std.org/JTC1/SC22/WG15/docs/rr/9945-2/9945-2-98.html
#	https://osdn.net/projects/yash/ticket/35283#comment:3863:35283:1435293070

_Msh_test=one/two/
push IFS
IFS=/
set -- ${_Msh_test}
pop IFS
case $# in
( 3 )	;;
( * )	return 1 ;;
esac
