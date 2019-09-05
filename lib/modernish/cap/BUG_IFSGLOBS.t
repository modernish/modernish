#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_IFSGLOBS: in glob pattern matching (as in 'case' or parameter
# substitution with # and %), if IFS starts with '?' or '*' and
# the "$*" parameter expansion inserts any IFS separator characters,
# those characters are erroneously interpreted as wildcards.
# Bug found in AT&T ksh93
# Ref: https://github.com/att/ast/issues/12

push IFS
_Msh_test=abcd
IFS=?; set -- a c		# "$*" is now "a?c"
case ${_Msh_test#"$*"},abc in	# the quoted "?" in "a?c" should not act as a wildcard
( d,"$*" )	;;		# it does: got bug
# expected result: abcd,abc
( * )		setstatus 1 ;;
esac
pop --keepstatus IFS
