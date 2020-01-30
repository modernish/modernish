#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_TRAPFNEXI: When a function issues a signal whose trap exits the shell,
# the shell is not exited immediately, but only on return from the function.
#
# Bug found on: zsh
# Ref.: http://www.zsh.org/mla/workers/2019/msg00045.html (zsh-workers 44007)
#	http://www.zsh.org/mla/workers/2020/msg00186.html (zsh-workers 45361)

# This bug can only be tested for reliably using dot script, as loops affect
# whether it is triggered or not, but a dot script undoes the effect of a loop.
# If this bug test is bundled/incorporated in bin/modernish using the -B option
# to install.sh, this bug test is not a dot script. So we have to use another
# auxiliary dot script to trigger it.

. "$MSH_AUX/cap/BUG_TRAPFNEXI.sh"

case ${_Msh_test} in
( trap${CCn}stillhere ) ;;
( * ) return 1 ;;
esac
