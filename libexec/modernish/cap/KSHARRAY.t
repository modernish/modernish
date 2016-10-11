#! /shell/capability/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# KSHARRAY: ksh88-style shell arrays (also on bash, and zsh under 'emulate sh')
# Note: this feature does not include mass assignment. See KSHARRAYASSG.
_Msh_test=''

# For shells without KSHARRAY, an array assignment looks like a command name.
# Make sure no external commands by that name are found.
push PATH
PATH=/dev/null
_Msh_test[0]=yes 2>/dev/null
pop PATH

# With KSHARRAY, a normal variable is identical to the fist element (0) of
# the array by the same name.
identic "${_Msh_test}" yes
