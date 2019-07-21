#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PUTIOERR: Shell builtins that output strings ('echo', 'printf', ksh/zsh 'print'), and thus also
# modernish 'put' and 'putln', do not check for I/O errors on output. This means a script cannot check
# for them, and a script process in a pipe can get stuck in an infinite loop if SIGPIPE is ignored.
#
# Bug found on: AT&T ksh93
# Ref.: https://github.com/att/ast/issues/1093

_Msh_test=$(
	{
		(
			\trap "" PIPE
			_Msh_test=0
			while let "(_Msh_test+=1) < 1000"; do
				putln xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx || exit
			done
			putln BUG >&2
		) | :
	} 2>&1
)

case ${_Msh_test} in
( BUG )	;;
( * )	return 1 ;;
esac
