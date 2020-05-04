#! /shell/capability/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# DBLBRACKET: The ksh88-style double-bracket command
# (NOT necessarily including '=~' or '-v').

thisshellhas --rw=[[ || return 1

(set -f
eval '[[ '\
'(abc == a?[bcd]*)'\
'&&-o noglob'\
'&&! / -nt /'\
'&&! / -ot /'\
"&&'a${CCn}b'<'a${CCn}bb'"\
"&&(! 'a${CCn}bb'<'a${CCn}b')"\
' ]]') 2>/dev/null || return 1

# Don't detect DBLBRACKET on mksh-R59: it ignores backslash-escaping of glob
# characters passed from variables, breaking the modernish match() function.
_Msh_test=a\\*e
! eval '[[ abcde == ${_Msh_test} ]]'
