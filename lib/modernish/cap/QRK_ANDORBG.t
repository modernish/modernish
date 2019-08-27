#! /shell/quirk/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# QRK_ANDORBG: On zsh, the '&' operator takes the last simple command
# as the background job and not an entire AND-OR list (if any).
#
# In other words:
#	a && b || c &
# is interpreted as
#	a && b || { c & }
# and not
#	{ a && b || c; } &
#
# This would be a bug, but POSIX (2018 ed.) is ambiguous on the matter.
# Ref.: http://austingroupbugs.net/view.php?id=1254
#	http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_09_03
#	zsh-workers 44705: http://www.zsh.org/mla/workers/2019/msg00741.html

case $- in
( *m* )	_Msh_test=$(_Msh_test=QRK && : & putln "${_Msh_test-}") ;;
( * )	_Msh_test=QRK && : & ;;
esac

case ${_Msh_test-} in
( QRK )	;;
( * )	return 1 ;;
esac
