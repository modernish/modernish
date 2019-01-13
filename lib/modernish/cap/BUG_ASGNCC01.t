#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_ASGNCC01: if IFS contains a $CC01 (^A) character, expansions in
# assignments discard that character (if present). Found on: bash 4.0-4.3
# Quoting the assignment value is an effective workaround.
# Ref.: https://lists.gnu.org/archive/html/bug-bash/2018-11/msg00081.html

push IFS
_Msh_test=X${CC01}X
IFS=$CC01
_Msh_test=${_Msh_test}
IFS=	# BUG_IFSCC01PP compat
pop IFS
str eq "${_Msh_test}" XX
