#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_KSHSUBVAR: ksh93: output redirection within a command substitution
# falsely resets the special ${.sh.subshell} variable to zero. Since ksh93 does
# subshells without forking, ${.sh.subshell} is the ONLY way on ksh93 to
# determine whether we're in a subshell or not.
#
# This bug affects the insubshell() function which is essential for die() and
# the trap stack. In particular, a command hardened and traced with 'harden -t'
# can't be properly killed on failure from a command substitution.
#
# This bug is only detected on ksh93, never on any other shells.
#
# (bug found in all ksh93 versions from 2010 and later :()

( eval '
	case $( (: 1>&1; echo ${.sh.subshell}) ) in
	( 0 )	return 0 ;;	# bug found
	( * )	return 1 ;;	# bug not found
	esac
' ) 2>/dev/null || return 1	# 'eval' fails on expanding ${.sh.subshell}: not ksh93, bug not applicable
