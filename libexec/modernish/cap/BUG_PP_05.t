#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PP_05: POSIX says that empty $@ generates zero fields, but
# with null IFS, empty unquoted $@ yields one empty field.
# Found on: dash 0.5.9.1

set --
push IFS
IFS=
set -- $@
pop IFS
case $# in
( 0 )	return 1 ;;
( 1 )	;;	# got bug
( * )	echo "BUG_PP_05.t: internal error"; return 2 ;;
esac
