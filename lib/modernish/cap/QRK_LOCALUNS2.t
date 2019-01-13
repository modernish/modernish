#! /shell/quirk/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# QRK_LOCALUNS2: This is a more treacherous version of QRK_LOCALUNS that is
# unique to bash. The 'unset' command works as expected when used on a local
# variable in the same scope that variable was declared in, HOWEVER, it
# makes local variables global again if they are unset in a subscope of that
# local scope, such as a function called by the function where it is local.
#
# As with QRK_LOCALUNS, this means 'unset' will not necessarily unset a
# variable if local variables are used!
#
# Ref.: the bug-bash thread starting at
# http://lists.gnu.org/archive/html/bug-bash/2017-03/msg00105.html

thisshellhas LOCALVARS || return	# not applicable

# This is a special case of QRK_LOCALUNS, so detecting both would be redundant.
thisshellhas QRK_LOCALUNS && return 1

_Msh_testFn2() {
	unset -v _Msh_test
	case "${_Msh_test-U}" in
	( 1 )	return 0 ;;	# got quirk
	( U )	return 1 ;;	# no quirk
	( 2 )	# undiscovered quirk
		return 1 ;;
	( * )	echo "QRK_LOCALUNS2: internal error"; return 2 ;;
	esac
}

_Msh_testFn1() {
	local _Msh_test
	_Msh_test=2
	_Msh_testFn2
}

_Msh_test=1
_Msh_testFn1

eval "unset -f _Msh_testFn1 _Msh_testFn2; return $?"
