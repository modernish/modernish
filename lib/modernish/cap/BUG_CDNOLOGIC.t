#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_CDNOLOGIC: the 'cd' built-in command does not have the POSIX-specified -L
# (logical traversal) option and always acts as if the -P (physical traversal)
# option was passed. This also makes the -L option to modernish chdir() a no-op.
#
# Found on: NetBSD sh

! (command cd -L /) 2>/dev/null
