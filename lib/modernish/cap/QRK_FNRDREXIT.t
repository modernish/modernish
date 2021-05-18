#! /shell/quirk/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# QRK_FNRDREXIT: On FreeBSD sh and NetBSD sh, an error in a
# redirection attached to a function call causes the shell to
# exit. POSIX allows this, at least for now:
# https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_08_01
# "Redirection error with function execution" is listed as "may exit"
# with a note that exit may be disallowed in a future version of the
# standard. Redirections of regular builtins "shall not exit".

! (
	_Msh_testFn() {
		command :
	}
	_Msh_testFn >/dev/null/nonexistent
	command :
) 2>| /dev/null
