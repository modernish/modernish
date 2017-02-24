#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_CMDSPASGN: AT&T ksh93: 'command' fails to make variable assignments
# non-persistent when using 'command' to make a special utility non-special.
#
# Reference:
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/command.html#tag_20_22
#	"If the command_name is the same as the name of one of the special
#	built-in utilities, the special properties in the enumerated list at
#	the beginning of Special Built-In Utilities shall not occur."
# which refers to:
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_14
#	"2. As described in Simple Commands, variable assignments preceding
#	the invocation of a special built-in utility remain in effect after
#	the built-in completes; this shall not be the case with a regular
#	built-in or other utility."
# See also: BUG_CMDSPEXIT

# Test the no-op command, ':', a "special built-in utility", making it
# non-special with 'command', so the variable assignment should *not*
# persist past the command.
_Msh_test=foo command :

# If it is still set, we've got the bug.
isset -v _Msh_test
