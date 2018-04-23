#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_ARITHLNNO: The shell supports $LINENO, but the variable cannot be
# used in all arithmetic contexts, like $(( LINENO > 0 )), because the
# variable is treated as unset. So it errors out with 'set -u' and
# is considered zero otherwise.
#
# Workaround: use the extra $, like $(( $LINENO > 0 )), to expand it before
# the arithmetic context is entered.
#
# Found on: FreeBSD sh, NetBSD sh 7 and earlier

thisshellhas LINENO || return 1  # not applicable

! ( let "$LINENO == $((LINENO))" ) 2>/dev/null
