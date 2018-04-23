#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_DQGLOB: Within double quotes, a '*' or '?' immediately following a
# backslash is interpreted as a globbing character -- meaning double quotes
# don't properly deactivate globbing. This applies to both pathname
# expansion and pattern matching in 'case'.
# Found in: dash (all versions to date).
# Ref.: https://www.spinics.net/lists/dash/msg01330.html

case \\foo in
( "\*" ) ;;
( * )	return 1 ;;
esac
