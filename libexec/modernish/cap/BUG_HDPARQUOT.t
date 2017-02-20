#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_HDPARQUOT: QUOTes within PARameter substitutions in Here-Documents
# aren't removed. For instance, if 'var' is set, ${var+"x"} in a here-
# document erroneously yields "x", not x.
# Found on: FreeBSD sh (10.3, 11.0)
IFS= read -r _Msh_test <<EOF
${_Msh_test-"word"}
EOF
case ${_Msh_test} in
( \"word\" ) ;;  # got bug
( word ) return 1 ;;
( * )	echo "BUG_HDPARQUOT.t: internal error: unknown bug with par.subst. in here-doc"
	return 2 ;;
esac
