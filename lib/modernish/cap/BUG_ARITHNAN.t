#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_ARITHNAN: In ksh <= 93u+m 2021-11-15 and zsh 5.6 - 5.8, the case-insensitive
# floating point constants Inf and NaN are recognised in arithmetic evaluation,
# overriding any variables with the names Inf, NaN, INF, nan, etc.

(
	command unset NaN || die "BUG_ARITHNAN.t: cannot uset NaN"
	NaN=0
	case $((NaN)) in
	( 0 )	\exit 1 ;;  # no bug
	esac
)
