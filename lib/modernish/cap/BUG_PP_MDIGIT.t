#! /shell/quirk/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PP_MDIGIT: Multiple-digit positional parameters don't require expansion
# braces, so e.g. $10 == ${10} (dash; Busybox ash). This is classed as a bug
# because it causes a straight-up incompatibility with POSIX scripts. POSIX
# says: "The parameter name or symbol can be enclosed in braces, which are
# optional except for positional parameters with more than one digit [...]".
# Ref.: https://www.mail-archive.com/dash@vger.kernel.org/msg01878.html

set -- 1 2 3 4 5 6 7 8 9 ten
case $10 in
( ten )	;;
( * )	return 1 ;;
esac
