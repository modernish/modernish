#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_CMDSPCIAL: zsh; mksh < R50e: 'command' does not turn off the 'special
# built-in' characteristics of special built-ins, such as exit shell on error.
# Ref.:	http://pubs.opengroup.org/onlinepubs/9699919799/utilities/command.html#tag_20_22
#	"If the command_name is the same as the name of one of the special
#	built-in utilities, the special properties in the enumerated list at
#	the beginning of Special Built-In Utilities shall not occur."
# This bug means that at least one of the tested commands unduly exits the
# shell when used with 'command'. Shells vary on which commands have this
# bug, but it would take forking one subshell each to test them separately,
# which is too expensive.

! (	command readonly _Msh_test

	command export _Msh_test=foo ||
	command unset -v _Msh_test ||
	command set -@ ||		# assumes -@ is an invalid shell option on every shell
	\exit 0

) 2>/dev/null
