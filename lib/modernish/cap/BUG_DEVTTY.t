#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_DEVTTY: the shell can't redirect output to /dev/tty if
# 'set -C'/'set -o noclobber' (part of safe mode) is active.
# Workaround: use '>| /dev/tty' instead of '> /dev/tty'.
#
# Bug found on: bash on certain systems (at least QNX and Interix).

push -C
set -C
# can only test this if we have a tty
if is charspecial /dev/tty >|/dev/tty; then
	command : >/dev/tty
	_Msh_test=$?
fi 2>/dev/null
pop -C
let "_Msh_test != 0"
