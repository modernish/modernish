#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_DOLRCSUB: parsing problem in bash where, inside a command substitution
# of the form $(...), the sequence $$'...' is treated as $'...' (i.e. as a
# use of CESCQUOT), and $$"..." as $"..." (bash-specific translatable string).
# Found in bash up to 4.4
# Ref.: https://groups.google.com/forum/#!search/messageid$3Ao6lnck$24n7c$241@news.xmission.com/comp.unix.shell/zzrE6UcoVq4/A_6nDJFDAwAJ
#	http://lists.gnu.org/archive/html/bug-bash/2017-01/msg00068.html

thisshellhas CESCQUOT || return  # not applicable

case $(IFS=''; PATH=$DEFPATH command echo $$'hi') in
# expected value:
# "$$"hi
( hi )	return 0 ;;  # bug
( * )	return 1 ;;
esac
