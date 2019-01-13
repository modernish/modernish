#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_TESTONEG: The test -o negative bug
# On yash (up to 2.43), the nonstandard -o operator for the test/[ builtin,
# which checks if a shell option is set, ignores no* in the option name,
# so something like [ -o noclobber ] gives a false positive.
# Ref.: https://osdn.jp/ticket/browse.php?group_id=3863&tid=36662

# If we don't have '['/'test' built in, none of this applies. /bin/[ or /bin/test could never check for a shell
# option as it can't have access. However, note we still need to set a standard utility $PATH for yash in POSIX
# mode, as it checks builtins against the presence of the external utility in $PATH before executing the builtin.

thisshellhas --bi=test || return 1

case $- in
( *C* )	set +C
	PATH=$DEFPATH command test -o noclobber
	case $? in
	( 0 ) set -C ;;
	( * ) set -C; return 1 ;;
	esac ;;
( * )	PATH=$DEFPATH command test -o noclobber
	case $? in
	( 0 ) ;;
	( * ) return 1 ;;
	esac ;;
esac 2>/dev/null
