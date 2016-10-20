#! /shell/capability/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# DOTARG: Arguments to dot scripts become positional parameters local to the
# dot script, as if they are shell functions.
#
# This test is used during modernish initialisation, so cannot use
# the full modernish functionalituy.

# _Msh_test is guaranteed to be unset on entry.
# _Msh_thisTestScript is guaranteed to be the path to this file.

if isset _Msh_test; then
	case "$#,${1-},${2-}" in
	( 2,one,two )	return 0 ;;
	( 0,, )		return 1 ;;
	( * )		echo "DOTARG.t: Undiscovered bug with arguments to dot scripts! ($#,${1-}.${2-})"
			return 2 ;;
	esac
fi

_Msh_test=''
set --	# clear PPs
. "${_Msh_thisTestScript}" one two
