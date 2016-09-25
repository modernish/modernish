#! /shell/capability/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# DOTARG: Dot scripts support arguments.
_Msh_test=
command . /dev/stdin one two <<-'EOF' 2>|/dev/null
_Msh_test="$# ${1-} ${2-}"
EOF
case ${?},${_Msh_test} in
( 0,'2 one two' )
	;;
( * )	return 1 ;;
esac
