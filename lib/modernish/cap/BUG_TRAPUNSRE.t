#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_TRAPUNSRE: When a trap UNSets itself and then REsends its own signal,
# the execution of the trap action (including functions called by it) is
# not interrupted by the now-untrapped signal; instead, the process
# terminates after completing the entire trap routine.
#
# Bug found on: bash <= 4.2; zsh
# Ref.: http://www.zsh.org/mla/workers/2019/msg00958.html

{ _Msh_test=$(
	# Store this subshell's PID in $REPLY.
	insubshell -p
	# In case some signal is ignored, try several.
	for _Msh_sig in ALRM HUP INT PIPE POLL PROF TERM USR1 USR2 VTALRM; do
		command trap "\
			putln trap
			command trap - ${_Msh_sig}
			command kill -s ${_Msh_sig} $REPLY
			putln stillhere
		" "${_Msh_sig}"
		str begin "${ZSH_VERSION:-}" 5.0. && set -x # TODO: remove when unsupporting zsh 5.0.8
		command kill -s "${_Msh_sig}" "$REPLY"
	done
); } 2>/dev/null

case ${_Msh_test} in
( trap${CCn}stillhere ) ;;
( * ) return 1 ;;
esac
