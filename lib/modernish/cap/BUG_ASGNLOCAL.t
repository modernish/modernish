#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_ASGNLOCAL: If you have a function-local variable with the same name as
# a global variable, and within the function you run a shell builtin command 
# with a temporary (command-local) variable assignment, then the global
# variable is unset.
#
# Bug found by Aryn Starr on: zsh <= 5.7.1
# Ref.: http://www.zsh.org/mla/workers/2019/msg00700.html

thisshellhas LOCALVARS || return 1	# not applicable
_Msh_test=
_Msh_testFn() {
	local _Msh_test
	_Msh_test=foo command true
}
_Msh_testFn
unset -f _Msh_testFn
not isset _Msh_test
