#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_TRAPRETIR: Using 'return' within 'eval' triggers infinite recursion
# if a RETURN trap and the 'functrace' shell option are active. This is
# a bug in bash-only functionality. (bash 4.3, 4.4)
# Ref.: https://lists.gnu.org/archive/html/bug-bash/2018-04/msg00047.html

(command trap - RETURN) 2>/dev/null && thisshellhas -o functrace || return 1  # not applicable

(
	command set -o functrace && command trap '_Msh_testFn' RETURN || die "BUG_TRAPRETIR.t: internal error"
	_Msh_test=0
	_Msh_testFn() {
		if let "(_Msh_test+=1) >= 4"; then
			command trap - RETURN || die "BUG_TRAPRETIR.t: internal error"
		fi
		eval "return"
	}
	_Msh_testFn
	let "_Msh_test >= 4"
)
