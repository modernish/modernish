#! /shell/capability/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# DOTARG: Arguments to dot scripts become positional parameters local to the
# dot script, as if they are shell functions.

# _Msh_test is unset on entry and $1 is the path to this file.

if isset _Msh_test; then
	unset -v _Msh_test
	case "$#,${1-},${2-}" in
	( 2,one,two )	return 0 ;;
	( 0,, )		return 1 ;;
	( * )		PATH=$DEFPATH command echo "DOTARG.t: internal error ($#,${1-}.${2-})"
			return 2 ;;
	esac
fi

_Msh_test=$1
set --	# clear PPs
if command . /dev/null one two 2>/dev/null; then
	# test if extra arguments are ignored
	command . "${_Msh_test}" one two
else
	# extra arguments are an error (yash -o posix)
	return 1
fi
