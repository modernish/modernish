#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_TESTERR1B: zsh: 'test'/'[' exits with status 1 (false) if there are
# too few or too many arguments, instead of a status > 1 as it should do.
# (zsh 5.3 fixes this)
PATH=$DEFPATH command test 123 -eq 2>/dev/null
case $? in
( 0 )	# Undiscovered bug with syntactically invalid 'test'/'[' expressions!
	return 1 ;;
( 1 )	;;
( * )	return 1 ;;
esac
