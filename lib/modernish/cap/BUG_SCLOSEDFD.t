#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_SCLOSEDFD: bash < 5.0 and dash fail to establish a block-local scope for
# a file descriptor that is added to the end of the block as a redirection that
# closes that file descriptor (e.g. '} 8<&-' or 'done 7>&-'). If that FD is
# already closed outside the block, the FD remains global, so you can't locally
# "exec" it. So with this bug, it is not straightforward to make a block-local
# FD appear initially closed within a block.
#
# Workaround: first open the FD, then close it. For example,
#	done 7>/dev/null 7>&-
# will establish a local scope for FD 7 for the preceding do...done block on
# shells with this bug, while still making FD 7 appear initially closed
# within the block.
#
# This bug is relevant to var/loop.mm.
#
# References:
# https://lists.gnu.org/archive/html/bug-bash/2018-04/msg00070.html
# https://www.spinics.net/lists/dash/msg01561.html

{
	{
		{
			# open the file descriptor to see if it leaks
			exec 8</dev/null
		} 8<&-
		# if this redirection succeeds, it's still open and we have the bug
		command : <&8 || return 1
	} 8<&- 2>/dev/null
} 8</dev/null	# BUG_SCLOSEDFD workaround
