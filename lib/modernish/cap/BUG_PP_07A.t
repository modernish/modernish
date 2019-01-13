#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PP_07A: When IFS is unset, unquoted $* undergoes word splitting as if
# IFS=' ', and not the expected IFS=" ${CCt}${CCn}". Unquoted $@ is
# correctly word-split as if IFS=" ${CCt}${CCn}".
#
# Found on: bash 4.4
#
# Bug reported on bug-bash by Kevin Brodsky in
# Message-ID: <707bc708-9c7a-c2dc-0bd3-67eddba698e6@gmail.com>

push IFS
unset -v IFS
set "a${CCn}b${CCt}c d"
set $*
pop IFS
case $# in
# expected $# value: 4
( 2 )	;;		# bug
( * )	return 1 ;;
esac
