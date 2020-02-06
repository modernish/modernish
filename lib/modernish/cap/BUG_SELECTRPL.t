#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_SELECTRPL: in a shell-native 'select' loop, input that is not a menu
# item is not stored in the REPLY variable as it should be.
#
# Bug found in mksh R50 2014/09/03.
# Known to be fixed as of mksh R50 2015/04/19.

thisshellhas --rw=select || return 1	# not applicable

echo ok | (case $(REPLY=newbug; eval 'select r in 1 2 3; do break; done'; echo "$REPLY") in
( ok )	exit 1 ;;	# ok, no bug
( '' )	;;		# mksh R50 bug
( newbug ) # Undiscovered bug with REPLY in 'select'!
	exit 1 ;;
( * )	echo "BUG_SELECTRPL.t: Internal error" 1>&3
	exit 2 ;;
esac 3>&2 2>/dev/null)
