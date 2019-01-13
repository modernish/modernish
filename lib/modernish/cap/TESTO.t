#! /shell/capability/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# TESTO: The test/[ builtin has a functional '-o' operator for testing
# whether a long-name shell option is active.

# **NOTE**: Never do this: [ ! -o optname ] It always yields positive, since
# '-o' as a logical OR operator takes precedence over '-o' as a shell option
# tester, so you're now testing if either the literal string '!' is
# non-empty, or the literal string 'optname' is non-empty.


# If we don't have '[' built in, none of this applies. /bin/[ could never
# check for a shell option as it can't have access.
thisshellhas [ || return 1

# This feature test is not compatible with BUG_TESTERR1B; we need '['
# to properly return an exit status 2 or higher on error.
thisshellhas BUG_TESTERR1B && return 1

# Test for [ -o.
# Also implicitly test against BUG_TESTONEG, a bug in yash where no* in the
# option name is ignored, so something like [ -o noclobber ] gives a false
# positive.
case $- in
( *C* )	set +C
	[ -o noclobber ]
	case $? in
	( 1 ) set -C ;;
	( * ) set -C; return 1 ;;
	esac ;;
( * )	[ -o noclobber ]
	case $? in
	( 1 ) ;;
	( * ) return 1 ;;
	esac ;;
esac 2>/dev/null
