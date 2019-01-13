#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_TRAPEMPT: The 'trap' command output does not quote empty traps,
# rendering the output unsuitable for shell re-input.
# (found in pdksh, mksh)

case $(command trap '' CONT; command trap) in
( "trap --  CONT" | "trap --  cont" )
    ;;  # bug
( * )
    return 1 ;;
esac
