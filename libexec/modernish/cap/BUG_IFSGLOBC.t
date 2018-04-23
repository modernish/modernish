#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_IFSGLOBC: in glob pattern matching (such as in 'case' and '[['), if a
# wildcard character is part of IFS, it is matched literally instead of as a
# matching character. This applies to glob characters '*', '?' and '['.
# Bug found in bash < 4.4.
# Ref: https://lists.gnu.org/archive/html/bug-bash/2016-07/msg00004.html

push IFS
IFS='*'
case foo in
( * )	pop IFS
	return 1 ;;			# no bug
esac
IFS=					# unbreak 'case' before pop
pop IFS
return 0				# bug
