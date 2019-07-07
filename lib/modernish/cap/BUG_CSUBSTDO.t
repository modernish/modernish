#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_CSUBSTDO: If standard output (file descriptor 1) is closed before
# entering a command substitution, and any other file descriptors are
# redirected within the command substitution, the 'echo', 'printf' and
# 'print' builtins (hence also modernish 'put' and 'putln') will not work
# within the command substitution, acting as if standard output is still
# closed.
#
# Bug found on: AT&T ksh93 <= AJM 93u+ 2012-08-01
#
# This bug is evidently related to NONFORKSUBSH (non-forking subshells on
# ksh93) because the workaround is to force the subshell to fork. This can
# be done in at least two ways:
# 1. Redirect standard output within the comm. subst. (even 1>&1 works), or
# 2. Use the `ulimit` builtin, like 'ulimit -t unlimited 2>/dev/null'.

{ _Msh_test=$(putln hi 2>/dev/null); } >&-
case ${_Msh_test} in
( '' )	;;
( * )	return 1 ;;
esac
