#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PSUBSQHD (Parameter Substitution Single Quotes Here-Document):
#
# Within a here-document, a parameter substitution of the form
# ${foo#'bar'}, ${foo##'bar'}, ${foo%'bar'} or ${foo%%'bar'}
# is not processed correctly: any pattern quoted with single
# quotes will not match.
#
# Bug found on dash, pdksh, mksh

_Msh_test=notOK
_Msh_test=$(command umask 077; PATH=$DEFPATH command cat <<-:
	${_Msh_test#'not'}
	:
)
case ${_Msh_test} in
# expected result:
# "OK"
( "notOK" )
	return 0 ;;  # bug
( * )	return 1 ;;
esac
