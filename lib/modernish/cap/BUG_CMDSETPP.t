#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_CMDSETPP: using 'command set --' has no effect; it does not set the
# positional parameters.
#
# Bug found on: mksh <= R57
# Ref.: https://www.mail-archive.com/miros-mksh@mirbsd.org/msg00861.html
set -- one two
command set -- one two three
case $# in
( 2 )	;;
( * )	return 1 ;;
esac
