#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_TESTERR1B: zsh: 'test'/'[' exits with status 1 (false) if there are
# too few or too many arguments, instead of a status > 1 as it should do.
# (zsh 5.3 fixes this)
# (zsh 4.1.1 needs 'eval' here to stop main shell from exiting on this error)
eval '[ 123 -eq ]' 2>| /dev/null
case $? in
( 0 )	echo "BUG_TESTERR1B.t: Undiscovered bug with syntactically invalid 'test'/'[' expressions!" 1>&2
	return 2 ;;
( 1 )	;;
( * )	return 1 ;;
esac
