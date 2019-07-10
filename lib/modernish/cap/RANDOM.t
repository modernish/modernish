#! /shell/capability/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# RANDOM: the $RANDOM pseudorandom generator present in many shells.
#
# Modernish has already either seeded or unset it, and has then set it to
# read-only, so this script can depend on that; no further checks needed.

case ${RANDOM-} in
( '' )	return 1 ;;
esac
