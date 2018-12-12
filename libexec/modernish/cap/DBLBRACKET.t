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
