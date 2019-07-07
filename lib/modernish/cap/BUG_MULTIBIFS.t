#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_MULTIBIFS: We're on a UTF-8 locale and the shell supports UTF-8
# characters in general (i.e. we don't have WRN_MULTIBYTE) -- however, using
# multibyte characters as IFS field delimiters still doesn't work. For
# example, "$*" joins positional parameters on the first byte of $IFS
# instead of the first character.
# Found on ksh93, mksh, FreeBSD sh, Busybox ash
# Ref.: https://github.com/att/ast/issues/13

case ${LC_ALL:-${LC_CTYPE:-${LANG:-}}} in
( *[Uu][Tt][Ff]8* | *[Uu][Tt][Ff]-8* )
	thisshellhas WRN_MULTIBYTE && return 1 ;;	# not applicable: redundant with WRN_MULTIBYTE
( * )	return 1 ;;					# not applicable: not in a UTF-8 locale
esac

push IFS
IFS=é
set -- : :
_Msh_test="$*"
pop IFS

# work around ksh93 shellquoting corruption, see https://github.com/att/ast/issues/13#issuecomment-335064372
LC_ALL=C command true	# BUG_CMDSPASGN compat: don't use "command :"

# test the result
case ${_Msh_test} in
( :é: )	return 1 ;;	# no bug
esac
