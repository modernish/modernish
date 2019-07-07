#! /shell/warning/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# WRN_MULTIBYTE: We're running on a locale with a variable-length character
# set (i.e. UTF-8) but the shell does not support multi-byte characters. For
# instance, ${#var} measures length in bytes, not characters.
# Note: Currently, WRN_MULTIBYTE is only detected if we're in a UTF-8 locale.
# (This is the only multibyte locale supported by current shells.)
# It should not be detected for single-byte locales as it's irrelevant there.

case ${LC_ALL:-${LC_CTYPE:-${LANG:-}}} in
( *.[Uu][Tt][Ff]8 | *.[Uu][Tt][Ff]-8 )
	_Msh_test='bèta' # 4 char, 5 byte UTF-8 string 'beta' with accent grave on 'e'
	case ${#_Msh_test} in
	( 5 )	;;
	( * )	return 1 ;;
	esac ;;
( * )	return 1 ;;
esac
