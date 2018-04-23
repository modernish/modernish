#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PP_10: another corner-case bug with assigning $* to a variable (i.e.:
# foo=$*). If IFS is empty, the $* expansion removes any $CC01 (^A) and $CC7F
# (DEL) characters. Quoting (i.e.: foo="$*") is an effective workaround.
#
# Found on: bash 3, 4

push IFS
IFS=
set -- "$CC01$CC02$CC03$CC7F"
_Msh_test=$*
pop IFS
case "${_Msh_test}" in
( "$CC02$CC03" )
	;;
( * )	return 1 ;;
esac
