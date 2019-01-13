#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_SELECTEOF: in a shell-native 'select' loop, the REPLY
# variable is not cleared if the user presses Ctrl-D to exit the loop.
# This means you can't test for this by testing the emptiness of
# $REPLY unless you empty REPLY yourself before entering the loop.
#
# Bug found on: zsh <= 5.2

thisshellhas --rw=select || return 1	# not applicable

# use 'eval' to avoid syntax errors on shells with no 'select'
case $(REPLY=bug; eval 'select _Msh_test in 1 2 3; do :; done'; echo "$REPLY") in
( bug )	;;  # found bug
( '' )	return 1 ;;
( * )	echo "BUG_SELECTEOF.t: Internal error" 1>&3
	return 2 ;;
esac </dev/null 3>&2 2>/dev/null
