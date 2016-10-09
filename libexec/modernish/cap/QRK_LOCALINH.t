#! /shell/quirk/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# QRK_LOCALINH: Local variables, when declared without assignment, initially
# inherit the state (set/unset, value, readonly status) of their global
# equivalent. (dash, FreeBSD sh)
thisshellhas LOCAL || return	# not applicable
_Msh_test=global
_Msh_testFn() {
	local _Msh_test
	case ${_Msh_test+s},${_Msh_test-} in
	( s,global ) ;;
	( s, )	return 1 ;;	# QRK_LOCALSET
	( , )	return 1 ;;
	( * )	echo "QRK_LOCALINH.t: Undiscovered quirk/bug with local variables!"
		return 2 ;;
	esac
}
_Msh_testFn
eval "unset -f _Msh_testFn; return $?"
