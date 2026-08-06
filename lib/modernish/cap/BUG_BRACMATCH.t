#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_BRACMATCH: certain non-ASCII characters will incorrectly match a
# pure-ASCII bracket expression in a glob pattern.
# Bug found on ksh93 on certain macOS versions. The bug is actually down to
# a bug in strxfrm(3) introduced on macOS 15.7 Sequoia.
# Ref.: https://github.com/ksh93/ksh/commit/ea0289759e891ef240aa26c9b4b6fb8

# Try to convert a paragraph sign to the current locale, then test it.
case $(PATH=$DEFPATH; command printf '\247\n' | command iconv -f ISO8859-1 2>/dev/null) in
[\|-])	# bug
	;;
*)	return 1 ;;
esac
