#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_ISSETLOOP: On AT&T ksh93, expansions like ${var+set}
# remain static when used within a 'for', 'while' or 'until' loop; the
# expansions don't change along with the state of the variable, so they cannot
# be used to check whether a variable is set within a loop if the
# state of that variable may change in the course of the loop.
#
# (found in AT&T ksh93, release and beta versions)
# Ref.: https://github.com/att/ast/issues/70

push _Msh_i _Msh_r
_Msh_r=
for _Msh_i in 1 2; do
	if str eq "${_Msh_r+s}" s; then
		_Msh_test=${_Msh_test-}s; unset -v _Msh_r
	else
		_Msh_test=${_Msh_test-}u; _Msh_r=
	fi
done
pop _Msh_i _Msh_r
str eq "${_Msh_test}" ss
