#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_EVALCOBR: 'break' and 'continue' do not work if they are within
# 'eval'.  An error message printed and then program execution continues as
# if these commands weren't given.
#
# Example problem situation: imagine a 'case' construct wrapped in 'eval' so
# it can use a variable referenced by another variable. This construct is
# within a loop and needs to be able to contionally break out of the loop
# based on the referenced variable's value. Since BUG_EVALCOBR won't
# tolerate the 'break' within the 'eval', the code needs to be more awkward:
# 'break' needs to be moved outside of the 'case' within the 'eval' while
# still keeping it conditional.
#
# Bug found in pdksh and in mksh.
# Known to be fixed as of mksh R55 2017/04/12.

for _Msh_test in 1; do
	eval "continue" 2>/dev/null
	return 0	# bug
done

for _Msh_test in 1; do
	eval "break" 2>/dev/null
	return 0	# bug
done

return 1		# no bug
