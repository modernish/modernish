#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_SCLOSEDFD: bash < 5.0 and dash <= 0.5.9.1 fail to save a closed file
# descriptor onto the shell-internal stack when added at the end of a block or
# loop (e.g. '} 8<&-' or 'done 7>&-'), so any 'exec' of that descriptor will
# leak out of the block. However, pushing an open file descriptor works fine.
#
# Workaround: enclose in another block that pushes the FD in an open state.
#
# References:
# https://lists.gnu.org/archive/html/bug-bash/2018-04/msg00070.html
# https://  TODO: dash list URL

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
