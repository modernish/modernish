#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_ALIASPOSX: bash in non-POSIX mode turns off alias expansion
# when the POSIXLY_CORRECT variable is temporarily exported for a command
# by preceding it as a variable assignment.
#
# Bug found on bash 4.2 through 5.0.
# Ref.: https://lists.gnu.org/archive/html/bug-bash/2020-01/msg00019.html

! (
	PATH=/dev/null
	unset -f shopt
	command unalias shopt

	command alias _Msh_test='! '

	unset -v POSIXLY_CORRECT  # this always disables alias expansion on non-interactive bash
	command -v shopt && command shopt -s expand_aliases

	# trigger bug
	POSIXLY_CORRECT=y command :

	# do we still have alias expansion?
	PATH=/dev/null command eval '_Msh_test { _Msh_test :; }'
) >/dev/null 2>&1
