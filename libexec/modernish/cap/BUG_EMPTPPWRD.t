#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_EMPTPPWRD: POSIX says that empty "$@" generates zero fields but empty ''
# or "" or "$emptyvariable" generates one empty field. This means concatenating
# "$@" with one or more other, separately quoted, empty strings (like
# "$@""$emptyvariable") should still produce one empty field. But on bash 3.x,
# this erroneously produces zero fields.
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
if thisshellhas BUG_UPP && isset -u; then
	set +u
	set -- ''"$@"''
	set -u
else
	set -- ''"$@"''	      # the quoted empties should join to one field, with "$@" treated as if it weren't there
fi
case $# in
( 0 )	return 0 ;;   # got bug
( 1 )	return 1 ;;
( * )	echo "BUG_EMPTPPWRD.t: Internal error: Undefined bug test result ($#)"
	return 2 ;;
esac
