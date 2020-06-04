#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_KBGPID: Due to a parser bug on AT&T ksh93, if a single command ending in
# '&' (i.e. a background job) is enclosed in a { braces; } block with a
# redirection, the value of the "$!" special parameter (the background job's
# PID) is not set to the background job's PID.
#
# E.g., with this bug, "$!" is unchanged after executing:
#	{
#		somecommand &
#	} >&2
#
# Workaround: ensure there is more than one command inside the { ... } block.
# Even a simple extra ':' will do.
#
# Ref.: https://github.com/att/ast/issues/1357


# Run everything in a subshell to avoid changing the main shell's "$!".
(
	set +u
	_Msh_test=$!

	{
		command true &
	} 1>&2

	# If "$!" didn't change, we have the bug.
	str eq "${_Msh_test-}" "$!"
)
