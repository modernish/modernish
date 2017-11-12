#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_SELECTRPL: in a shell-native 'select' loop, input that is not a menu
# item is not stored in the REPLY variable as it should be.
#
# Unfortunately, circumventing the bug by replacing 'select' with
# modernish's 'select' implementation from var/loop/select.mm is impossible
# because 'select' is a reserved word and cannot be replaced.
#
# Bug found in mksh R50 2014/09/03.
# Known to be fixed as of mksh R50 2015/04/19.

thisshellhas --rw=select || return 1	# not applicable

case $(REPLY=newbug; eval 'select r in 1 2 3; do break; done'; echo "$REPLY") in
( ok )	return 1 ;;	# ok, no bug
( '' )	;;		# mksh R50 bug
( newbug ) # Undiscovered bug with REPLY in 'select'!
	return 1 ;;
( * )	echo "BUG_SELECTRPL.t: Internal error" 1>&3
	return 2 ;;
esac <<'EOF' 3>&2 2>/dev/null
ok
EOF
