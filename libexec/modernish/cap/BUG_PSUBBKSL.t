#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PSUBBKSL (bash 2 & 3, standard dash, Busybox ash)
# A backslash-escaped character within a quoted parameter substitution is
# not unescaped.
#	Note: quoting a '}' with anything other than a backslash *within* a
#	parameter substitution, e.g. ${var+"\}"}, is invalid as that may be
#	considered an unbalanced quote (") within ${...}. In practice, shells
#	produce varying results, although none actually gives an error. See
#	http://www.unix.org/whitepapers/shdiffs.html under "Parameter
#	Expansion".
# Note: for the detection of this bug it is important that the whole
# substitution is quoted, even though this is not supposed to make a
# difference in 'case'.
_Msh_test=somevalue
case "${_Msh_test+\}}" in
( '}' ) return 1 ;;
( '\}' ) ;;
( * )	echo "BUG_PSUBBKSL.t: Undiscovered bug with backslash in parameter substitution!" 1>&2
	return 2 ;;
esac
