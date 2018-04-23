#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PP_05: POSIX says that empty $@ and $* generate zero fields, but
# with null IFS, empty unquoted $@ and $* yields one empty field.
# Found on: dash 0.5.9.1

set --
push IFS
IFS=
set -- $@ $*
pop IFS
case $# in
( 2 )	;;	# got bug
( * )	return 1 ;;
esac
