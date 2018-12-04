#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_TRAPSUB0: Subshells in traps fail to pass down a nonzero exit status
# of the last command, either under certain conditions or consistently,
# depending on the shell.
#
# We collect all variants under this one bug ID because the workaround is the
# same in every case: use an explicit exit like 'exit 1' or 'exit $?' to exit
# any subshell that might be executed by a trap (directly or indirectly).
#
# Found on:
# - bash 3.2, 4.0: only for exiting on errors (e.g. assigning to readonly)
# - dash 0.5.9-0.5.10.2: consistently for signals; intermittently for EXIT
#   Ref.: https://www.spinics.net/lists/dash/msg01750.html
# - yash <= 2.47: consistent, EXIT traps only
#   Ref.: https://osdn.net/projects/yash/ticket/38774

# BUG_TRAPEXIT compat: use '0' not 'EXIT'
(command trap 'readonly _Msh_test=foo; (_Msh_test=bar) 2>/dev/null && exit 13' 0)
case $? in
( 13 )	;;  # bug
( * )	return 1 ;;
esac
