#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_VARPREFIX: The shell has VARPREFIX, but expansions of type ${!prefix@}
# and ${!prefix*} do not include the variable name 'prefix' itself. (ksh93)
# Ref.: https://github.com/ksh93/ksh/issues/183

thisshellhas VARPREFIX || return 1	# not applicable
_Msh_test=
set -- "${!_Msh_test@}"
str ne "${1-}" _Msh_test
