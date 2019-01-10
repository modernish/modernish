#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_MULTIBYTE: We're running on a locale with a variable-length character
# set (i.e. UTF-8) but the shell does not support multi-byte characters. For
# instance, ${#var} measures length in bytes, not characters. With
# fixed-length one-byte character sets, the bug is irrelevant so we don't
# set the identifier. Current shells with this bug include dash and most
# branches of pdksh.
# Note: Currently, BUG_MULTIBYTE is only detected if we're in a UTF-8 locale.
# (This is the only multibyte locale supported by current shells.)
# It should not be detected for single-byte locales as it's irrelevant there.
# Ref.: http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_06_02

case ${LC_ALL:-${LC_CTYPE:-${LANG:-}}} in
( *.[Uu][Tt][Ff]8 | *.[Uu][Tt][Ff]-8 )
	_Msh_test='bèta' # 4 char, 5 byte UTF-8 string 'beta' with accent grave on 'e'
	case ${#_Msh_test} in
	( 5 )	;;
	( * )	return 1 ;;
	esac ;;
( * )	return 1 ;;
esac
