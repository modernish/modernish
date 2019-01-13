#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_IFSGLOBP: in pathname expansion (filename globbing), if a
# wildcard character is part of IFS, it is matched literally instead of as a
# matching character. This applies to glob characters '*', '?' and '['.
# Bug found in bash (all versions up to at least 4.4).
# Ref: https://lists.gnu.org/archive/html/bug-bash/2016-11/msg00013.html

# Save IFS (note: _Msh_test is guaranteed unset at start)
isset IFS && _Msh_test=$IFS

# Turn on globbing temporarily if it's off (set -f)
case $- in
( *f* )	set +f
	IFS='*'			# BUG_IFSGLOBC compat: don't set IFS before "case"
	set -- /*
	set -f ;;
( * )	IFS='*'
	set -- /* ;;
esac

# Restore IFS
case ${_Msh_test+s} in		# BUG_IFSGLOBC compat: no wildcards in this 'case'
( s )	IFS=${_Msh_test} ;;
( '' )	unset -v IFS ;;
esac

# Check if the glob pattern expanded; if not, bug
let "$# == 1" && str eq "$1" "/*"
