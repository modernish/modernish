#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_CASESTAT: The 'case' conditional construct prematurely clobbers the exit status ("$?").
# (found in zsh < 5.3, Busybox ash <= 1.25.0, dash < 0.5.9.1)
# Ref.:	http://www.zsh.org/mla/zsh-workers/39596
#	https://bugs.busybox.net/show_bug.cgi?id=9311
#	https://git.kernel.org/cgit/utils/dash/dash.git/commit/?id=da534b740e628512e8e0e62729d6a2ef521e5096

! :	# this is like 'false' but can't be overridden or disabled

case foo in
( * )	_Msh_test=$? ;;
esac

case ${_Msh_test-} in
( 0 )	;;  # bug
( 1 )	return 1 ;;
( * )	# Undiscovered bug with testing exit status in 'case'! (2)
	return 1 ;;
esac
