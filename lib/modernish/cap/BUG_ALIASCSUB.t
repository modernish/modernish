#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_ALIASCSUB: parsing problem in mksh where, inside a command substitution
# of the form $(...), shell block constructs expanded from a pair of aliases
# cannot have a newline after the first alias; a misleading syntax error about
# an unexpected ';' is generated (even if there is no ';').
#
# This bug affects var/local (LOCAL...BEGIN...END) and var/loop
# (LOOP...DO...DONE). Workarounds: have a statement on the same line
# after DO or BEGIN, or use the `backtick form` instead.
#
# Another way to trigger this bug (which is now irrelevant to modernish
# as the var/(set)local syntax changed) is described in the reference.
#
# Found in: mksh/lksh up to R54 (2016/11/11).
# Ref.: https://www.mail-archive.com/miros-mksh@mirbsd.org/msg00749.html

! (
	command alias _Msh_1='{ ' _Msh_2='}'
	eval ': $(_Msh_1  # newline here triggers bug
		: ; _Msh_2)'
) 2>/dev/null
