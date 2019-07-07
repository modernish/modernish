#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_EXPORTUNS: Setting the export flag on an otherwise unset variable
# causes a set and empty environment variable to be exported, though the
# variable continues to be considered unset within the current shell.
#
# Bug found on: FreeBSD sh < 13.0
#
# Ref.:	https://www.mail-archive.com/austin-group-l@opengroup.org/msg04441.html
#	https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=233545

export _Msh_test
case $(PATH=$DEFPATH "$MSH_SHELL" -c 'echo "${_Msh_test+SET}"') in
( SET )	;;
( * )	return 1 ;;
esac
