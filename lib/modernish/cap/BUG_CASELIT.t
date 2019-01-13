#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_CASELIT: If a 'case' pattern doesn't match as a pattern, it's tried
# again as a literal string, even if the pattern isn't quoted. This can
# result in false positives when a pattern doesn't match itself, like with
# bracket patterns. This contravenes POSIX and breaks use cases such as
# input validation. (AT&T ksh93)
# Ref.:	https://github.com/att/ast/issues/476
#	https://www.mail-archive.com/austin-group-l@opengroup.org/msg02127.html

case '[0-9]' in
( [0-9] ) ;;
( * )	return 1 ;;
esac
