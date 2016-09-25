#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_BRACSQBR: the closing square bracket ']', even if escaped or passed
# from a quote variable, produces a false positive in negated ('!') bracket
# patterns, i.e. the pattern is never matched. (FreeBSD /bin/sh)
# (This bug is the reason why $SHELLSAFECHARS can't contain ']'; it would
# break shellquote() on the shell with this bug)
case e in
( *[!ab\]cd]* ) return 1 ;;
esac
