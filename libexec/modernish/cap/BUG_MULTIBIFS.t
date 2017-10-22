#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_MULTIBIFS: We're on a UTF-8 locale and the shell supports UTF-8
# characters in general (i.e. we don't have BUG_MULTIBYTE) -- however, using
# multibyte characters as IFS field delimiters still doesn't work. For
# example, "$*" joins positional parameters on the first byte of $IFS
# instead of the first character.
# Found on ksh93 and mksh
# Ref.: https://github.com/att/ast/issues/13

thisshellhas BUG_MULTIBYTE && return 1	# not applicable

push IFS LC_ALL
IFS=é
set -- : :
_Msh_test="$*"	# https://github.com/att/ast/issues/13#issuecomment-335064372
LC_ALL=C	# workaround for ksh93 shellquoting corruption (see URL above)
case ${_Msh_test} in
( :é: )	setstatus 1 ;;	# no bug
esac
pop --keepstatus IFS LC_ALL
