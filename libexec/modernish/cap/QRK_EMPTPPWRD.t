#! /shell/quirk/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# QRK_EMPTPPWRD: POSIX says that empty "$@" generates zero fields but empty
# '' or "" or "$emptyvariable" generates one empty field. But it leaves
# unspecified whether something like "$@$emptyvariable" generates zero
# fields or one field. Zsh, pdksh/mksh and (d)ash generate one field, as
# seems logical. But bash, AT&T ksh and yash generate zero fields, which we
# consider a quirk.
# Ref.: http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_05_02
#   "[...] If there are no positional parameters, the expansion of '@' shall
#   generate zero fields, even when '@' is within double-quotes; however, if
#   the expansion is embedded within a word which contains one or more other
#   parts that expand to a quoted null string, these null string(s) shall
#   still produce an empty field, except that if the other parts are all
#   within the same double-quotes as the '@', it is unspecified whether the
#   result is zero fields or one empty field."
# See also BUG_EMPTYPPWRD.

set --
_Msh_test=''
set -- "${_Msh_test}$@${_Msh_test}"
case $# in
( 0 )	return 0 ;;   # got quirk
( 1 )	return 1 ;;
( * )	# undiscovered bug
	return 1 ;;
esac
