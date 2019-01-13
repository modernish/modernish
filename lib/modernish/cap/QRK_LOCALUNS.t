#! /shell/quirk/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# QRK_LOCALUNS: The 'unset' command makes local variables global again, even
# if the local variable is initialised to an unset state (yash, pdksh/mksh).
# Note: this is actually a behaviour of the 'typeset' builtin, to which
# 'local' is aliased on these shells.
thisshellhas LOCALVARS || return	# not applicable
# _Msh_test is guaranteed to be unset on entry.
_Msh_testFn() {
	local _Msh_test
	unset -v _Msh_test
	_Msh_test=global
}
_Msh_testFn
unset -f _Msh_testFn
case ${_Msh_test+s},${_Msh_test-} in
( s,global ) ;;
( , )	return 1 ;;
( * )	# Undiscovered quirk/bug with unsetting local variables
	return 1 ;;
esac
