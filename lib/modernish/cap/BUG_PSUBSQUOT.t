#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PSUBSQUOT: in pattern matching parameter substitutions like
#	${param#pattern}
#	${param%pattern}
#	${param##pattern}
#	${param%%pattern}
# if the whole parameter substitution itself is quoted with double quotes,
# then single quotes in the /pattern/ are not parsed. POSIX says
# they should keep their special meaning, so that glob characters may
# be quoted. For example: x=foobar; echo "${x#'foo'}" should yield 'bar'
# but with this bug yields 'foobar'.
#
# Reference: 2.6.2 Parameter Expansion at
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_06_02
#  | The following four varieties of parameter expansion provide for
#  | substring processing. [...] Enclosing the full parameter expansion
#  | string in double-quotes shall not cause the following four varieties
#  | of pattern characters to be quoted, whereas quoting characters
#  | within the braces shall have this effect.
# Discussion:
# https://www.mail-archive.com/austin-group-l@opengroup.org/msg00197.html
# https://www.mail-archive.com/dash@vger.kernel.org/msg01355.html
#
# Bug found on: dash; Busybox ash

_Msh_test=foobar
case "${_Msh_test#'foo'}" in
( bar )	return 1 ;;
( foobar ) ;;
( * )	# something weird going on, but this bug isn't it
	return 1 ;;
esac
