#! /shell/quirk/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# QRK_EXECFNBI: In pdksh and zsh, 'exec' looks up shell functions and
# builtins before external commands, and if it finds one it does the
# equivalent of running the function or builtin followed by 'exit'. This is
# probably a bug in POSIX terms; 'exec' is supposed to launch a program that
# overlays the current shell, implying the program launched by 'exec' is
# always external to the shell. However, since the POSIX language is rather
# vague and possibly incorrect, this is labeled as a shell quirk instead of
# a shell bug.
# https://www.mail-archive.com/austin-group-l@opengroup.org/msg01440.html
# https://www.mail-archive.com/austin-group-l@opengroup.org/msg01469.html
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_20
(
	_Msh_QRK_EXECFNBI_test() {
		exec :
	}
	PATH=/dev/null
	MSH_NOT_FOUND_OK=y		# so 'use safe -k' won't kill the program
	exec _Msh_QRK_EXECFNBI_test	# this is 'command not found' on shells without QRK_EXECFNBI
) 2>/dev/null || return 1
