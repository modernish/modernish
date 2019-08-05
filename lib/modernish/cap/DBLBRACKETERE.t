#! /shell/capability/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# DBLBRACKETERE: The ksh93-style double-bracket command (including ERE matching with '=~').

thisshellhas DBLBRACKET || return 1

(
	_Msh_test='^(ONE [[:punct:][:alpha:]]{4,9} TWO[[:space:]]){2}$'
	eval '[[ "ONE S@Me TWO${CCv}ONE t;hi,n.gs TWO${CCn}" =~ ${_Msh_test} ]]'
) 2>/dev/null || return 1
