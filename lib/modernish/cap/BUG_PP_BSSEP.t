#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PP_BSSEP: When IFS is empty and there are empty positional parameters,
# the expansion "$*" produces a spurious backslash for the empty parameters,
# if used in a context where glob pattern expansion would have been possible.
# Bug found in: ksh 93u+m < 1.0.11

set a '' b '' c
push IFS
IFS=
case abc in
"$*")	! : ;;  # no bug: return 1/false
esac
pop --keepstatus IFS
