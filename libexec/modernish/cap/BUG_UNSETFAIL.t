#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_UNSETFAIL: the 'unset' command sets a non-zero (fail) exit status if
# the variable to unset was either not set (some pdksh versions), or never
# set before (AT&T ksh 1993-12-28). This is contrary to POSIX, which says:
# "Unsetting a variable or function that was not previously set shall not be
# considered an error [...]". Reference:
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_29_03
# Good thing we don't support "set -e". Still, this bug can affect the exit
# status of functions and dot scripts if 'unset' is the last command.
unset -v _Msh_test
! unset -v _Msh_test
