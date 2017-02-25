#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_KSHSUBVAR: ksh93: output redirection within a command substitution
# falsely resets the special ${.sh.subshell} variable to zero. Since ksh93 does
# non-background subshells without forking, ${.sh.subshell} is the ONLY
# canonical way on ksh93 to determine whether we're in a non-background
# subshell or not. (It has never worked for background subshells.)
#
# This bug affects the insubshell() function which is essential for die() and
# the trap stack. In particular, a command hardened and traced with 'harden -t'
# can't be properly killed on failure from a command substitution.
# However, an available workaround is to (ab)use BUG_FNSUBSH, which all ksh93
# versions have. See the comments near insubshell() in bin/modernish.
#
# This bug is only detected on ksh93, never on any other shells.
#
# (bug found in all ksh93 versions from 2010 and later :()

thisshellhas KSH93FUNC || return 1	# not applicable

command eval '
	case $( (: 1>&1; echo ${.sh.subshell}) ) in
	( 0 )	return 0 ;;	# bug found
	( * )	return 1 ;;	# bug not found
	esac
'
