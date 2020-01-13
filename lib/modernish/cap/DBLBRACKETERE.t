#! /shell/capability/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# DBLBRACKETERE: The ksh93-style double-bracket command (including ERE matching with '=~').

thisshellhas DBLBRACKET || return 1

(
	_Msh_test='^(ONE [[:punct:][:alpha:]]{4,9} TWO[[:space:]]){2}$'
	eval '[[ "ONE S@Me TWO${CCv}ONE t;hi,n.gs TWO${CCn}" =~ ${_Msh_test} ]]' || exit 1

	case ${LC_ALL:-${LC_CTYPE:-${LANG:-}}} in
	( *.[Uu][Tt][Ff]8 | *.[Uu][Tt][Ff]-8 )
		if not thisshellhas WRN_MULTIBYTE; then
			# This UTF-8 match crashes bash 4.4.12 on NetBSD
			_Msh_test='^(ONÉ [[:punct:][:alpha:]]{4,9} TWÖ[[:space:]]){2}$'
			eval '[[ "ONÉ S@Mé TWÖ${CCv}ONÉ t;hï,ñ.gs TWÖ${CCn}" =~ ${_Msh_test} ]]'
		fi ;;
	esac
) 2>/dev/null || return 1
