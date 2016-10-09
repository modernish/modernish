#! /shell/quirk/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# QRK_LOCALSET: Local variables are set to the empty value upon being declared,
# as opposed to remaining unset until used. (zsh; bash 2 and 3)
thisshellhas LOCAL || return	# not applicable
unset -v _Msh_test
_Msh_testFn() {
	local _Msh_test
	case ${_Msh_test+s} in
	( '' )	return 1 ;;
	esac
}
_Msh_testFn
case $?,${_Msh_test+s} in
( 0, )	unset -f _Msh_testFn; return 0 ;;
( 1, )	unset -f _Msh_testFn; return 1 ;;
( * )	echo "QRK_LOCALSET.t: Undiscovered bug with local variables!"
	return 2 ;;
esac
