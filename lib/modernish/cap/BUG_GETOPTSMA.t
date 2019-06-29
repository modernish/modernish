#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_GETOPTSMA: The getopts builtin leaves a ':' instead of a '?' in the
# option variable if an option that requires an argument lacks an argument,
# and the option string does not start with a ':'.
#
# Bug found on: zsh <= 5.7.1
# Ref.: zsh-workers 44469: http://www.zsh.org/mla/workers/2019/msg00505.html

# This bug test can only work reliably on zsh if we make OPTIND function-local,
# as this also makes getopts' hidden internal state local to the function. But
# that means we cannot test for this on shells without local variables.
thisshellhas LOCALVARS || return 1

# Even though we declare OPTIND local, run the whole thing in a subshell
# anyway, just to be sure -- shells all behave differently with 'getopts' in
# a function, and we don't want to mess up any hidden global internal state.
_Msh_test=$(
	_Msh_testFn() {
		local OPTIND
		while command getopts x: _Msh_test 2>/dev/null; do
			putln "${_Msh_test}"
		done
	}
	# -x without mandatory argument triggers error from getopts;
	# with the bug, _Msh_test is set to ':'; without, '?'.
	_Msh_testFn -x
)

case ${_Msh_test} in
( ':' )	;;
( * )	return 1 ;;
esac
