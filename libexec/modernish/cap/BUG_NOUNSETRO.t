#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_NOUNSETRO: Cannot freeze variables as readonly in an unset state.
# This bug in zsh < 5.0.8 makes the 'readonly' command set them to the
# empty string instead. For BUG_NOUNSETRO compatibility, modernish library
# code should not depend on the unset status of read-only variables.
# Notes on test compatibility with other shell bugs:
# * For BUG_UNSETFAIL compatibility, don't use 'unset ... && readonly ...'
# * ksh93 version "M 1993-12-28 r" has a parsing bug: it will erroneously
#   stop script execution on
#	test "${_Msh_ReadOnlyTest+set}" = ""
#   with a "_Msh_ReadOnlyTest: read-only variable" error, indicating the
#   wrong line number. But this ONLY happens if that command is in a
#   subshell! Yet it stops the main script! So to avoid locking out ksh93,
#   don't use a subshell (this speeds up our init anyway) and accept that we
#   have a permanent _Msh_ReadOnlyTest unset readonly.
unset -v _Msh_testNOUNSETRO
readonly _Msh_testNOUNSETRO
case ${_Msh_testNOUNSETRO+s} in
( s )	;;
( * )	return 1 ;;
esac
