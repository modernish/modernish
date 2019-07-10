#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_KUNSETIFS: Can't unset IFS on ksh93 under very specific circumstances.
#
# 'unset IFS' or 'unset -v IFS' is a known POSIX shell idiom to activate
# default field splitting. With this bug, the 'unset' builtin silently fails
# to unset IFS if all three of the following conditions are met:
#
#  1. IFS is set and empty in the main shell (i.e. split is disabled).
#  2. We're in a subshell.
#  3. We're executing an 'eval' or a trap.
#
# Re 2, it makes no difference whether the subshell is within the 'eval' or
# the 'eval' is within the subshell.
#
# The bug is not triggered for any other variable -- just IFS.
#
# Note that, due to BUG_IFSISSET (also on ksh93), this bug cannot normally be
# easily tested for because it is not possible to test in any normal way if
# IFS is set. Modernish isset() contains a workaround, so can be used below.
#
# Workaround: assign anything to IFS (even the empty value that was already
# there) immediately before unsetting it. This makes 'unset' work again.
# Or, maybe better: force the subshell to fork using 'ulimit -t unlimited'.

push IFS
IFS=''
_Msh_test='unset -v IFS; isset -v IFS'   # 'isset' returns 0 (got bug) if IFS is still set
(eval "${_Msh_test}")
pop --keepstatus IFS
