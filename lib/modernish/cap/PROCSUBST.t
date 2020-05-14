#! /shell/capability/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# PROCSUBST: the shell natively supports <(process substitution), a special
# kind of command substitution that substitutes a file name, connecting it
# to a background process running your command(s).
#
# This exists on ksh93 and zsh.
# (Bash has it too, but its POSIX mode turns it off, so modernish can't use it.)
#
# Note this is usually combined with a redirection, like < <(command). Contrast
# this with yash's PROCREDIR where the same <(syntax) is itself a redirection.

(
	command ulimit -t unlimited	# ksh93: force subshell to fork to avoid bugs
	command umask 777
	eval 'IFS= read -r _Msh_test < <(putln PROCSUBST)' \
	&& str eq "${_Msh_test}" PROCSUBST
) </dev/null 2>/dev/null || return 1
