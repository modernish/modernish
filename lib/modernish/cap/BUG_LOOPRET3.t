#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_LOOPRET3: If a 'return' command is given within the set of conditional
# commands in a 'while' or 'until' loop (i.e., between 'while'/'until' and
# 'do'), and the return status (either the status argument to 'return' or the
# exit status passed down from the previous command by 'return' without a
# status argument) is non-zero, and the conditional command list itself yields
# false (for 'while') or true (for 'until'), and the whole construct is
# executed in a dot script sourced from another script, then too many levels of
# loop are broken out of, causing program flow corruption or premature exit.
# Found on: zsh <= 5.7.1
# Ref.: zsh-workers 44271, http://www.zsh.org/mla/workers/2019/msg00309.html

# Run dot script in subshell to stop bug corrupting program flow in main shell
( . "$MSH_AUX/cap/BUG_LOOPRET3.sh"
  # With the bug, the 'exit' below is never executed
  \exit 42 )

case $? in
( 0 )	;;
( * )	return 1 ;;
esac
