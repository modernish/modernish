#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_LNNOEVAL: an mksh/pdksh bug: LINENO is zero when used in 'eval'.

thisshellhas LINENO || return 1  # not applicable

eval '_Msh_test=$LINENO'
case ${_Msh_test} in
( 0 )	;;
( * )	return 1 ;;
esac
