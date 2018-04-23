#! /shell/bug/test/for/moderni/sh
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
	_Msh_testD=$(unset -v D i
		umask 077
		i=0
		until D=/tmp/_Msh_BUG_APPENDC.$$.$i; PATH=$DEFPATH command mkdir "$D" 2>/dev/null; do
			case $? in
			( 126 )	exit 2 "BUG_APPENDC.t: system error: could not invoke 'mkdir'" ;;
			( 127 ) exit 2 "BUG_APPENDC.t: system error: command not found: 'mkdir'" ;;
			esac
			is -L dir /tmp && can write /tmp || exit 2 "BUG_APPENDC.t: system error: /tmp directory not writable"
			i=$((i+1))
		done
		echo "$D"
		# Test if "appending" under 'set -C' creates a file
		set -C
		{ : >> "$D/file"; } 2>/dev/null
	)
	_Msh_test=$?
	case $- in
	( *i* )	PATH=$DEFPATH command rm -rf "${_Msh_testD}" ;;
	( * )	PATH=$DEFPATH command rm -rf "${_Msh_testD}" & ;;
	esac
	unset -v _Msh_testD
	case ${_Msh_test} in
	( 0 )	return 1 ;;
	( 1 )	return 0 ;;
	( * )	return 2 ;;
	esac
	;;
( * )
	return 1
	;;
esac
