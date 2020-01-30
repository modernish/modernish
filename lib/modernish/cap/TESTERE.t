#! /shell/capability/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# TESTERE: The '=~' extended regular expression matching operator in the builtin 'test'/'[' command.

thisshellhas --bi=test || return 1

_Msh_test='^(ONE [[:punct:][:alpha:]]{4,9} TWO[[:space:]]){2}$'
PATH=$DEFPATH command test "ONE S@Me TWO${CCv}ONE t;hi,n.gs TWO${CCn}" "=~" "${_Msh_test}" 2>/dev/null || return 1

case ${LC_ALL:-${LC_CTYPE:-${LANG:-}}} in
( *.[Uu][Tt][Ff]8 | *.[Uu][Tt][Ff]-8 )
	if ! thisshellhas WRN_MULTIBYTE; then
		_Msh_test='^(ONÉ [[:punct:][:alpha:]]{4,9} TWÖ[[:space:]]){2}$'
		PATH=$DEFPATH command test "ONÉ S@Mé TWÖ${CCv}ONÉ t;hï,ñ.gs TWÖ${CCn}" "=~" "${_Msh_test}" 2>/dev/null || return 1
	fi ;;
esac
