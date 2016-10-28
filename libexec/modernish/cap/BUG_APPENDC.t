#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_APPENDC: On zsh < 5.1, when set -C (noclobber) is active, "appending" to
# a nonexistent file with '>>' throws an error rather than creating the file.
# This is long-standing zsh behaviour, but is contrary to the POSIX spec and
# different from every other shell, so it's a legit POSIX compliance bug.
# The error may cause the shell to exit, so must fork a subshell to test it.
# This is another bug affecting 'use safe'.
# Ref.: http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_07_03
#	http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_25
# This bug test is essential for 'use safe' but too involved. It's very
# unlikely that it exists on POSIXy shells other than zsh or ever will.
# Until evidence indicating otherwise appears, I'm holding my nose and doing
# shell version checking in a bug test, so only zsh gets the cost.
case ${ZSH_VERSION+z} in
( z )
	(	umask 077
		set -C
		RANDOM=$$
		# Find a nonexistent filename
		i=$RANDOM
		until F=/tmp/_Msh_BUG_APPENDC.$i; not is present "$F" && is -L dir /tmp && can write /tmp; do
			i=$RANDOM
			if not is -L dir /tmp || not can write /tmp; then
				echo "BUG_APPENDC.t: /tmp directory not found or not writable!" 1>&3
				exit 2
			fi
		done
		# Test if "appending" creates it
		: >> "$F" && { rm -f "$F" & }
	) 3>&2 2>/dev/null
	case $? in
	( 0 )	return 1 ;;
	( 1 )	return 0 ;;
	( * )	return 2 ;;
	esac
	;;
( * )
	return 1
	;;
esac
