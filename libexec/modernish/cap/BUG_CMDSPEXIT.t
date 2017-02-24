#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_CMDSPEXIT: zsh; mksh < R50e: 'command' does not stop special builtins
# from exiting the shell on error.
# Ref.:	http://pubs.opengroup.org/onlinepubs/9699919799/utilities/command.html#tag_20_22
#	"If the command_name is the same as the name of one of the special
#	built-in utilities, the special properties in the enumerated list at
#	the beginning of Special Built-In Utilities shall not occur."
# which refers to:
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_14
#	"1. An error in a special built-in utility may cause a shell
#	executing that utility to abort, while an error in a regular
#	built-in utility shall not cause a shell executing that utility to
#	abort. [...]"
# Note: shells vary on which commands cause the shell to exit in spite of the
# use of 'command'; for instance, on ksh and variants, assignments to readonly
# variables using 'command export' cause the shell to exit.
# See also: BUG_CMDSPASGN

! (	command set -@ ||		# assumes -@ is an invalid shell option on every shell
	\exit 0
) 2>/dev/null
