#! /shell/capability/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# LEPIPEMAIN (execute Last Element of pipe in main shell)
# Most shells, when using a pipe construct such as:
#	command1 | command2 | command3
# execute each element of the pipe in its own subshell. This means any
# changes in variables done in 'command1', 'command2' and 'command3' are
# lost. But shells with LEPIPEMAIN, while still launching a subshell for
# 'command1' and 'command2', execute the last element of the pipe
# in the main shell. This means you can do something like:
#	somecommand | read VAR
# and have $VAR take effect in the main shell.
# Shells known to have LEPIPEMAIN are: zsh and AT&T ksh (not pdksh or mksh).
# Also, bash 4.2 and up with 'shopt -s lastpipe', but only if job control is
# disabled (set +m), which is usually the case for scripts only.

# _Msh_test is guaranteed to be unset on entry.

: | _Msh_test=
case ${_Msh_test+s} in
( s )	;;
( * )	return 1 ;;
esac
