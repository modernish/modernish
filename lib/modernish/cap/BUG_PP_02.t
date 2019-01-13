#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PP_02: POSIX says that empty "$@" generates zero fields but empty ''
# or "" or "$emptyvariable" generates one empty field. This means
# concatenating $@ with one or more other, separately quoted, empty strings
# (like $@"$emptyvariable") should still produce one empty field. But on
# pdksh, this erroneously produces zero fields if an empty string is
# concatenated with $@ (in that order). FreeBSD 10.3 sh also has a variant
# of this bug.
# Ref.: http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_05_02
#   "[...] If there are no positional parameters, the expansion of '@' shall
#   generate zero fields, even when '@' is within double-quotes; however, if
#   the expansion is embedded within a word which contains one or more other
#   parts that expand to a quoted null string, these null string(s) shall
#   still produce an empty field, except that if the other parts are all
#   within the same double-quotes as the '@', it is unspecified whether the
#   result is zero fields or one empty field."

set --
set -- ''$@	      # the quoted empty and $@ should join to one field, with $@ treated as if it weren't there
case $# in
# expected $# value: 1
( 0 )	return 0 ;;   # got bug
( * )	return 1 ;;
esac
