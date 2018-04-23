#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_LNNOALIAS: an mksh/pdksh bug: LINENO is zero during alias expansion.

thisshellhas LINENO || return 1  # not applicable

alias _Msh_BUG_LNNOALIAS_testAlias='_Msh_test=$LINENO'
eval _Msh_BUG_LNNOALIAS_testAlias
unalias _Msh_BUG_LNNOALIAS_testAlias
case ${_Msh_test} in
( 0 )	;;
( * )	return 1 ;;
esac
