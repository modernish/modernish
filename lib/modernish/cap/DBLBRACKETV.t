#! /shell/capability/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# DBLBRACKETV: The '-v' operator in the double-bracket command, which tests if a variable is set.

thisshellhas DBLBRACKET || return 1

# Note: modernish guarantees an unset _Msh_test on entry.
(eval '[[ '\
'! -v _Msh_test '\
'&&-n ${_Msh_test=foo}'\
'&&-v _Msh_test'\
' ]]') 2>/dev/null || return 1
