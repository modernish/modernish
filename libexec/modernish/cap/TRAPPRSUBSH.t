#! /shell/capability/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# TRAPPRSUBSH: ability to print the parent shell's native traps from a command substitution, even if,
# instead of the trap builtin directly, we call a shell function that invokes the trap builtin. Ref.:
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_28_03
#	| When a subshell is entered, traps that are not being ignored shall be set to the
#	| default actions, except in the case of a command substitution containing only a
#	| single trap command, when the traps need not be altered. [...]
# Note that modernish reimplements this feature on shells without this capability.

case $(	command trap ': TRAPPRSUBSH_Ks6UoNqP' 0  # BUG_TRAPEXIT compat
	_Msh_testFn() {
		command trap
	}
	put "$(_Msh_testFn)"
     ) in
( *': TRAPPRSUBSH_Ks6UoNqP'* )
	;;
( * )	return 1 ;;
esac
