#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_UNSETUNXP: If an unset variable is given the export flag using
# the 'export' command, a subsequent 'unset' command does not remove
# that export flag again.
#
# Workaround: set the variable first, then unset it to unexport it.
#
# Bug found on:
# - AT&T ksh JM-93u-2011-02-08
# - Busybox 1.27.0 ash

export _Msh_test
unset -v _Msh_test
isset -x _Msh_test
