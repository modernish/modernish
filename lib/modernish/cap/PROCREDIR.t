#! /shell/capability/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# PROCREDIR: the shell natively supports <(process redirection), a special
# kind of redirection that connects standard input (or standard output)
# to a background process running your command(s).
#
# This exists on yash.
#
# Note this is NOT combined with a redirection like < <(command). Contrast
# with bash/ksh/zsh's PROCSUBST where this <(syntax) substitutes a file name.

(
	eval 'IFS= read -r _Msh_test <(putln PROCREDIR)' \
	&& str eq "${_Msh_test}" PROCREDIR
) </dev/null 2>/dev/null || return 1
