#! /shell/quirk/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# QRK_PPIPEMAIN: in all elements of a pipeline, parameter expansions are
# evaluated in the current shell environment, with any changes they make
# surviving the pipeline. (zsh <= 5.5.1)

: ${_Msh_test=QRK} | :
case ${_Msh_test-} in
( QRK )	;;
( * )	return 1 ;;
esac
