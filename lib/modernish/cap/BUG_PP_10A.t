#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PP_10A: another corner-case bug with assigning $* to a variable (i.e.:
# foo=$*). If IFS is non-empty, the $* expansion prefixes each $CC01 (^A) and
# $CC7F (DEL) characters with a $CC01 character. Quoting (i.e.: foo="$*") is an
# effective workaround.
#
# Found on: bash 4.4

push IFS
IFS=' '
set -- "$CC01$CC02$CC03$CC7F"
_Msh_test=$*
pop IFS
case "${_Msh_test}" in
( "$CC01$CC01$CC02$CC03$CC01$CC7F" )
	;;
( * )	return 1 ;;
esac
