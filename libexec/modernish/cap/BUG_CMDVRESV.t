#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_CMDVRESV: 'command -v' does not find reserved words such as "if", contrary
# to POSIX. This bug affects modernish's thisshellhas function. The bug is in
# mksh R50f (2015/04/19) and earlier, as well as its ancestor pdksh and its variants.
# Fixed in mksh R51 (2015/07/05).
# Ref: http://pubs.opengroup.org/onlinepubs/9699919799/utilities/command.html#tag_20_22
_Msh_cmdv_PATH=$PATH
PATH=/dev/null
if command -v if >| /dev/null 2>&1; then
	PATH=${_Msh_cmdv_PATH}
	unset -v _Msh_cmdv_PATH
	return 1
else
	PATH=${_Msh_cmdv_PATH}
	unset -v _Msh_cmdv_PATH
fi
