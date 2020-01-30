#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_LNNONEG: $LINENO becomes wildly inaccurate, even negative, when
# dotting/sourcing scripts.
#
# Bug found on: dash (if LINENO support is compiled in, which it isn't on
# dash as used in Debian-based installations).

. "$MSH_AUX/cap/BUG_LNNONEG.sh"
: # need no-op for mksh to update LINENO before 'case'.
case ${_Msh_test} in
( "${LINENO-}" )
	return 1 ;;
( -* )	;;
( * )	return 1 ;;
esac
