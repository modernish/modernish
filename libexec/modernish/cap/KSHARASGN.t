#! /shell/capability/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# KSHARASGN: ksh93-style shell array mass assignments (also on bash, and
# zsh under 'emulate sh').

thisshellhas KSHARRAY || return 1	# not appplicable

( eval '_Msh_test=(one two three) &&
	identic "${_Msh_test[0]}" one &&
	let "${#_Msh_test[@]}==3"'
) 2>/dev/null || return 1
