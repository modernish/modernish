#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_BRACQUOT: shell quoting within bracket patterns has no effect (zsh < 5.3;
# ksh93) This bug means the '-' retains it special meaning of 'character
# range', and an initial '!' (and, on some shells, '^') retains the meaning of
# negation, even in quoted strings within bracket patterns, including quoted
# variables. This makes it difficult to pass arbitrary strings of characters to
# match against using a bracket pattern. Workaround: make sure the '-' is last
# in the string of characters to match, and the string does not start with '^'
# or '!'.
# This bug requires a workaround for trim() in var/string.mm, and it's also the
# reason the '-' needs to always be last in the readonly SHELLSAFECHARS.
case b in
( ['a-c'] | ["!"a] ) ;;	# bug
( [a-c] ) return 1 ;;	# no bug
( * )	# Undiscovered bug with bracket pattern matching
	return 1 ;;
esac
