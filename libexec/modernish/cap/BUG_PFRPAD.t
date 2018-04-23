#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PFRPAD: Negative padding value for strings in 'printf' does not
# cause blank padding on the right-hand side, but inserts blank padding
# on the left-hand side as if the value were positive. (zsh 5.0.8)
thisshellhas printf || return 1  # not applicable
case $(printf '%-4s' hi) in
( '  hi' ) ;;
( * )	return 1 ;;
esac
