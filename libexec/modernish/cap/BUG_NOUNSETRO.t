#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_NOUNSETRO: Cannot freeze variables as readonly in an unset state.
# This bug in zsh < 5.0.8 makes the 'readonly' command set them to the
# empty string instead. For BUG_NOUNSETRO compatibility, modernish library
# code should not depend on the unset status of read-only variables.
# Notes on test compatibility with other shell bugs:
# * For BUG_UNSETFAIL compatibility, don't use 'unset ... && readonly ...'
# * ksh93 version "M 1993-12-28 r" segfaults on executing the test below
#   in a normal subshell due to bugs in its non-forking implementation of
#   subshells. Workaround: make it a background job, and acquire the
#   background job's exit status using 'wait "$!"'. This workaround
#   carries no measurable performance hit on other shells. However, it
#   produces job control clutter on interactive shells, so do it only
#   if job control is disabled. If not, put up with a permanent
#   test readonly.
case $- in
( *m* )	unset -v _Msh_testNOUNSETRO
	readonly _Msh_testNOUNSETRO
	case ${_Msh_testNOUNSETRO+s} in
	( s )	;;
	( * )	return 1 ;;
	esac
	;;
( * )	{
		(
			unset -v _Msh_testNOUNSETRO
			readonly _Msh_testNOUNSETRO
			case ${_Msh_testNOUNSETRO+s} in
			( s )	;;
			( * )	\exit 1 ;;
			esac
		) & wait "$!"
	} >/dev/null 2>&1
	;;
esac
