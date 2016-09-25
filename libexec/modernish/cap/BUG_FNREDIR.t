#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_FNREDIR: I/O redirections on function definition commands are not
# remembered or honoured when the function is executed. (zsh4)
# Ref.: http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_09_05
#	On zsh, his test function produces a false positive:
#		_Msh_testFn() { echo hi; } 1>&-
#	because zsh incorrectly returns with exit status 0 on failing to
#	write to a closed stdout. The following does work on zsh. However,
#	zsh exits on the resulting write error, so we need a subshell.
_Msh_testFn() {
	echo hi 1>&2
} 2>&-
if (_Msh_testFn) 2>|/dev/null; then
	unset -f _Msh_testFn
	return 0
else
	unset -f _Msh_testFn
	return 1
fi
