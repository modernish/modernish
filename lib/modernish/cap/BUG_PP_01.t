#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PP_01: POSIX says that empty "$@" generates zero fields but empty ''
# or "" or "$emptyvariable" generates one empty field. This means concatenating
# "$@" with one or more other, separately quoted, empty strings (like
# "$@""$emptyvariable") should still produce one empty field. But on bash 3.x,
# and older mksh, this erroneously produces zero fields.
#
# This bug is detected on bash 3.x for both ''"$@"'' and ''"$@"
# but only for ''"$@" on older mksh, so test just the latter pattern.
#
# Ref.: http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_05_02
#   "[...] If there are no positional parameters, the expansion of '@' shall
#   generate zero fields, even when '@' is within double-quotes; however, if
#   the expansion is embedded within a word which contains one or more other
#   parts that expand to a quoted null string, these null string(s) shall
#   still produce an empty field, except that if the other parts are all
#   within the same double-quotes as the '@', it is unspecified whether the
#   result is zero fields or one empty field."
# See also QRK_EMPTYPPWRD.

set --
set -- ''"$@"	      # the quoted empties should join to one field, with "$@" treated as if it weren't there
case $# in
# expected $# value: 1
( 0 )	return 0 ;;   # got bug
( * )	return 1 ;;
esac
