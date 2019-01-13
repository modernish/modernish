#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_HDOCBKSL (Here-DOCument BacKSLash):
# Backslash line continuation within expanding here-documents
# is handled incorrectly:
#
# 1. With "<<-EOF", leading tabs are incorrectly stripped after line
#    continuation. http://www.zsh.org/mla/workers/2018/msg00147.html
#
# 2. Line continuation does not work before a line that looks like
#    the delimiter, so the delimiter is incorrectly recognised.
#    http://www.zsh.org/mla/workers/2018/msg00156.html
#
# 3. The delimiter cannot be split using line continuation.
#    http://www.zsh.org/mla/workers/2018/msg00161.html
#
# Bug found on zsh up to 5.4.2
# Ref.: zsh-workers 42340, 42349, 42354, 42355

_Msh_test=$(command umask 077; PATH=$DEFPATH command cat <<-:
	abc
	def \
	ghi
	jkl\
	:
	:
)
case ${_Msh_test} in
# expected result:
# "abc${CCn}def ${CCt}ghi${CCn}jkl${CCt}:"
( "abc${CCn}def ghi${CCn}jkl" )
	return 0 ;;  # bug
( * )	return 1 ;;
esac
