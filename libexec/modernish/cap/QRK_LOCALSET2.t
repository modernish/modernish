#! /shell/quirk/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# QRK_LOCALSET2: As with QRK_LOCALSET, local variables are set to the empty
# value upon being declared, as opposed to remaining unset until used. However,
# that happens *only* if the variable was unset in the parent/global scope. If
# it was globally set, the variable is unset upon being declared. (bash 2, 3)

thisshellhas LOCALVARS || return	# not applicable
# _Msh_test is guaranteed to be unset on entry.
_Msh_test2=set
_Msh_testFn() {
	local _Msh_test _Msh_test2
	case ${_Msh_test+s1}${_Msh_test2+s2} in
	(s1)	return 0 ;;
	esac
	return 1
}
_Msh_testFn
case $?,${_Msh_test+s1},${_Msh_test2+s2} in
(0,,s2)	unset -f _Msh_testFn; unset -v _Msh_test2; return 0 ;;
( * )	unset -f _Msh_testFn; unset -v _Msh_test2; return 1 ;;
esac
