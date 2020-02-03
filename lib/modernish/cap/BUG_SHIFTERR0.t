#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_SHIFTERR0: The 'shift' builtin silently returns a successful exit
# status (0) when attempting to shift a number greater than the current
# amount of positional parameters.
#
# Bug found on: Busybox ash <= 1.28.4

(
	set -- 1 2 3
	shift 4
) 2>/dev/null || return 1
