#! /shell/warning/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# WRN_EREMBYTE: We're running on a locale with a variable-length character
# set (i.e. UTF-8) but the engine used by 'str ematch' to match extended
# regular expressions (EREs) does not support multibyte characters.
#
# Note: Currently, WRN_EREMBYTE is only detected if we're in a UTF-8 locale.
# (This is the only multibyte locale supported by current shells and utilities.)
# It should not be detected for single-byte locales as it's irrelevant there.

case ${LC_ALL:-${LC_CTYPE:-${LANG:-}}} in
( *.[Uu][Tt][Ff]8 | *.[Uu][Tt][Ff]-8 )
	! str ematch "ONÉ S@Mé TWÖ${CCv}ONÉ t;hï,ñ.gs TWÖ${CCn}" \
		'^(ONÉ [[:punct:][:alpha:]]{4,9} TWÖ[[:space:]]){2}$' ;;
( * )	return 1 ;;
esac
