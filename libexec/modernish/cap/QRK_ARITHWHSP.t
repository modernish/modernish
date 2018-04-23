#! /shell/quirk/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# QRK_ARITHWHSP: In yash and FreeBSD /bin/sh, trailing whitespace from
# variables is not trimmed in arithmetic expansion, causing the shell to
# exit with an 'invalid number' error. POSIX is silent on the issue.
# https://osdn.jp/ticket/browse.php?group_id=3863&tid=36002
#
# bash, dash and zsh 
case $(	_Msh_test="$CCt 1"		# tab, space, 1
	: $((_Msh_test)) || exit	# (need 'exit' because yash in interactive mode doesn\'t) [BUG_CSCMTQUOT compat]
	put a1
	_Msh_test="1$CCt "		# 1, tab, space
	: $((_Msh_test)) || exit
	put a2
) in
( '' )	return 1 ;;	# undiscovered quirk: leading whitespace is not trimmed
(a1)	;;		# got the quirk
(a1a2)	return 1 ;;
( * )	putln 'QRK_ARITHWHSP.t: internal error' 2>&3; return 2 ;;
esac 3>&2 2>/dev/null
