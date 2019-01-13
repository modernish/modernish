#! /shell/capability/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# NONFORKSUBSH: Subshells without forking a new process.
# Only ksh93 has this, and it's very buggy...

# The extra ':' commands are to defeat optimisations on various shells.
_Msh_test=$("$MSH_SHELL" -u -c 'echo $PPID' && ("$MSH_SHELL" -u -c 'echo $PPID'; :); :)
case ${_Msh_test} in
( *${CCn}* )
	# If the two PIDs are the same, subshells are part of the same process.
	case "${_Msh_test%%${CCn}*}" in
	( "${_Msh_test#*${CCn}}" ) ;;
	( * )	return 1 ;;
	esac ;;
( * )	return 1 ;;
esac
