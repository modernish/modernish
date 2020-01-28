#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_CSUBRMLF: A bug affecting the stripping of final linefeeds from
# command substitutions. If a command substitution does not produce any
# output to substitute *and* is concatenated in a string or here-document,
# then the shell strips any concurrent linefeeds occurring directly before
# the command substitution in that string or here-document.
#
# Bug found on: dash <= 0.5.10.2, Busybox ash, FreeBSD sh
# Ref.: https://www.spinics.net/lists/dash/msg01844.html

_Msh_test=one${CCn}$( : )two
case ${_Msh_test} in
# expected value: one${CCn}two
( onetwo ) ;;
( * )	return 1 ;;
esac
