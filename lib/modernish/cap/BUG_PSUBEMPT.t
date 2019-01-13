#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PSUBEMPT: Expansions of the form ${1-} and ${1:-} are not subject to
# normal shell empty removal if that positional parameter doesn't exist,
# causing unexpected empty arguments to commands. (FreeBSD 10.3 sh)
#
# Workaround: ${1+$1} and ${1:+$1} work as expected.

set --
set -- ${1-}
case $# in
( 1 )	;;
( * )	return 1 ;;
esac
