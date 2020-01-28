#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PUTIOERR: Shell builtins that output strings ('printf', ksh/zsh 'print'), and thus also
# modernish 'put' and 'putln', do not check for I/O errors on output. This means a script cannot check
# for them, and a script process in a pipe can get stuck in an infinite loop if SIGPIPE is ignored.
#
# Bug found on: AT&T ksh93
# Ref.: https://github.com/att/ast/issues/1093

# Test the same command that put/putln would use... (see bin/modernish)
if thisshellhas --bi=print; then
	set -- print -r --
else
	set -- printf '%s\n'
fi

_Msh_test=$(
	{
		(
			PATH=$DEFPATH
			command trap "" PIPE
			_Msh_test=0
			while let "(_Msh_test+=1) < 1000"; do
				command "$@" xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx || exit
			done
			command "$@" BUG >&2
		) | :
	} 2>&1
)

case ${_Msh_test} in
( BUG )	;;
( * )	return 1 ;;
esac
