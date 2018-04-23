#! /shell/capability/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# Test if we have $LINENO (current shell script line number).
# POSIX mandates this, but dash on Debian is compiled without it.

_Msh_test=${LINENO-}
: # need no-op for mksh to update LINENO before 'case'.
case ${_Msh_test} in
( "${LINENO-}" ) unset -v LINENO; return 1 ;;
esac
#readonly LINENO	# (Note: pdksh/oksh don't cope with making it read-only)
