#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_EVALCOBR: 'break' and 'continue' do not work correctly if they are
# within 'eval'.
#
# On pdksh and mksh <= R55 2017/04/12, an error message printed and then
# program execution continues as if these commands weren't given.
#
# On FreeBSD 10.3 /bin/sh, if 'continue' or 'break' is not the last command
# within the 'eval', then commands on subsequent lines within 'eval' are
# spuriously executed before 'continue' or 'break' is belatedly honoured.
#
# Example problem situation: imagine a 'case' construct wrapped in 'eval' so
# it can use a variable referenced by another variable. This construct is
# within a loop and needs to be able to contionally break out of the loop
# based on the referenced variable's value. Since BUG_EVALCOBR won't
# tolerate the 'break' within the 'eval', the code needs to be more awkward:
# 'break' needs to be moved outside of the 'case' within the 'eval' while
# still keeping it conditional.

for _Msh_test in 1; do
	eval "command continue${CCn}return 0" 2>/dev/null
done

for _Msh_test in 1; do
	eval "command break${CCn}return 0" 2>/dev/null
done

return 1		# no bug
