#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_CC7F: Quoted expansions delete the DEL control character ($CC7F),
# except if that character is directly preceded by ^A ($CC01).
# (found in bash 2.05b, 3.0)

_Msh_test=ab${CC7F}cd${CC01}${CC7F}ef
_Msh_test="${_Msh_test}"
case "${_Msh_test}" in
( abcd${CC01}${CC7F}ef ) ;;	# bash 3.0.16
( abcddef ) ;;			# bash 2.05b
( * )	return 1 ;;
esac
