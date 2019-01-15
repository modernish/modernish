#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_XTRCREDIR: Redirecting stderr for a simple command redirects the
# xtrace too. This can cause problems, e.g. with v=$(cmd 2>&1) and xtrace
# active, the trace of 'cmd' becomes part of the value of 'v'.
# Found on:
# - yash <= 2.47, ref.: https://osdn.net/projects/yash/ticket/38748
# - AT&T ksh93: xtrace of preceding variable assignments is redirected

{ _Msh_test=$(set -x; PATH=$DEFPATH command true 2>&1); } 2>/dev/null
case ${_Msh_test} in
( '' )	return 1 ;;
esac
