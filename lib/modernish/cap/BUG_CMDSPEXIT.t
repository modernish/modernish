#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_CMDSPEXIT: 'command' does not stop all special builtins from exiting the shell on error.
# (bash <= 4.0; zsh <= 5.2; mksh; ksh93)
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
# use of 'command'. Left out of this test are 'command eval "("' because generating
# a syntax error in the main shell causes too many shells to either exit or become
# crash-prone, as well as 'command exec /dev/null/nonexistent' where every shell exits.
# See also: BUG_CMDSPASGN

! (	command set -@		# assumes -@ is an invalid shell option on every shell
	command readonly _Msh_test=foo
	command export _Msh_test=bar
	command . /dev/null/nonexistent
	\exit 0
) 2>/dev/null
