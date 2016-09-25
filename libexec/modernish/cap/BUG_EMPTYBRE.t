#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_EMPTYBRE is a 'case' pattern matching bug in zsh: empty bracket
# expressions eat subsequent shell grammar, producing unexpected results (in
# the test example below, a false positive match, because the two patterns
# are taken as one, with the "|" being taken as part of the bracket
# expression rather than shell grammar separating two bracket expressions).
# This is particularly bad if you want to pass a bracket expression using a
# variable or parameter, and that variable or parameter could be empty. This
# means the grammar parsing depends on the contents of the variable!
# This is fixed as of zsh 5.0.8, but *only* in POSIX/'emulate sh' mode.
# (yash < 2.15 also had this bug.)
_Msh_test=''
case abc in
( ["${_Msh_test}"] | [!a-z]* )
	;;
( * )	return 1 ;;
esac
