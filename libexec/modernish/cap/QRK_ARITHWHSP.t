#! /shell/quirk/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# QRK_ARITHWHSP: In yash and FreeBSD /bin/sh, trailing whitespace from
# variables is not trimmed in arithmetic expansion, causing the shell to
# exit with an 'invalid number' error. POSIX is silent on the issue.
# https://osdn.jp/ticket/browse.php?group_id=3863&tid=36002
case $(	_Msh_test="$CCt 1"		# tab, space, 1
	: $((_Msh_test)) || exit	# (need 'exit' because yash in interactive mode doesn\'t) [BUG_CSCMTQUOT compat]
	echo a1
	_Msh_test="1$CCt "		# 1, tab, space
	: $((_Msh_test)) || exit
	echo a2
) in
( '' )	die 'QRK_ARITHWHSP.t: Undiscovered whitespace quirk in arithmetic expansion! Please report.' 2>&3 ;;
( a1 )	;;	# got the quirk
( a1*a2 ) return 1 ;;
( * )	die 'QRK_ARITHWHSP.t: Internal error in QRK_ARITHWHSP test! Please report.' 2>&3 ;;
esac 3>&2 2>/dev/null
