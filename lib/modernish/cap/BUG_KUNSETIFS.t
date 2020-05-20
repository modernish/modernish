#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_KUNSETIFS: On AT&T ksh93, unsetting IFS fails to activate default
# field splitting if the following conditions are met:
#
#  1. IFS is set and empty (i.e. split is disabled) in the main shell,
#     and at least one expansion has been processed with that setting.
#  2. The code is currently executing in a non-forked/virtual subshell
#     (see NONFORKSUBSH).
#
# Workaround: assign anything to IFS (even the empty value that was already
# there) immediately before unsetting it. This makes 'unset' work again.
# Or, maybe better: force the subshell to fork using 'ulimit -t unlimited'.

push IFS
IFS=''		# condition 1: no split in main shell
: ${_Msh_test-}	# at least one expansion is also needed to trigger this
(		# condition 2: subshell (non-forked)
	unset -v IFS
	_Msh_test="one two three"
	set -- ${_Msh_test}
	let "$# == 1"	# without bug, should be 3
)
pop --keepstatus IFS
