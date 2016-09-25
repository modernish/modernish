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
! (	unset -v _Msh_test
	: $((_Msh_test = 1))
	_Msh_test=a:b:c  # zsh: bad math expression: ':' without '?'
) 2>|/dev/null
