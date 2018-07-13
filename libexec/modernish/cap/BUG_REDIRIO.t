#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_REDIRIO: the I/O redirection operator <> (open a file descriptor for both
# read and write) defaults to opening standard output (i.e. is short for 1<>)
# instead of defaulting to opening standard input (0<>) as POSIX specifies.
# (found in ksh93)
# Ref.: http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_07_07

case $(PATH=$DEFPATH command echo hi <>/dev/null) in
( '' )	return 0 ;;	# bug: standard output was redirected
( hi )	return 1 ;;	# no bug
( * )	PATH=$DEFPATH command echo "BUG_REDIRIO: internal error" >&2
	return 1 ;;
esac >/dev/null
