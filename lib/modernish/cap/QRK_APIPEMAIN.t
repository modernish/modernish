#! /shell/quirk/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# QRK_APIPEMAIN: any element of a pipeline that is nothing but a
# simple variable assignment is executed in the current
# environment. (zsh < 5.3)

_Msh_test=QRK | :
case ${_Msh_test-} in
( QRK )	;;
( * )	return 1 ;;
esac
