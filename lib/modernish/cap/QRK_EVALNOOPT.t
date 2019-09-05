#! /shell/quirk/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# QRK_EVALNOOPT: 'eval' does not parse options, not even '--', which makes it
# incompatible with other shells: on the one hand, (d)ash does not accept
# 'eval -- "$command"' whereas on other shells this is necessary if the command
# starts with a '-', or the command would be interpreted as an option to
# 'eval'. A simple workaround is to prefix arbitrary commands with a space. See:
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_19_16
# Both situations are POSIX compliant, but since they are incompatible
# without a workaround, let's label the minority situation as a QuiRK.
_Msh_qrkEval_PATH=$PATH
PATH=/dev/null	# avoid any external command called '--'
if ! eval -- ':' 2>|/dev/null; then
	PATH=${_Msh_qrkEval_PATH}
	unset -v _Msh_qrkEval_PATH
else
	PATH=${_Msh_qrkEval_PATH}
	unset -v _Msh_qrkEval_PATH
	return 1
fi
