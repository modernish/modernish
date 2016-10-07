#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_ARITHTYPE: In zsh < 5.3, arithmetic assignments (using 'let', '$(( ))',
# etc.) on unset variables assign a numerical/arithmetic type to a variable,
# causing subsequent normal variable assignments to be interpreted as
# arithmetic expressions and fail if they are not valid as such. This is an
# incompatibility with the POSIX shell, which is a typeless language.
# To work around this bug, either make sure variables are not used for a
# non-integer data type after arith assignment, or set them to an empty
# value before using them.
unset -v _Msh_test
: $((_Msh_test = 1))	# does this assign an arithmetic type restriction?
_Msh_test=128/32	# let's see...
case ${_Msh_test} in
( 128/32 ) return 1 ;;
( 4 )	;;		# bug found
( * )	echo "BUG_ARITHTYPE.t: Undiscovered bug with variable type restriction!" 1>&2
	return 2 ;;
esac
