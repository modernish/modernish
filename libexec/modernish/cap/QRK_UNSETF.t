#! /shell/quirk/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# QRK_UNSETF: if 'unset' is invoked without any option flag (-v or -f), and
# no variable by the given name exists but a function does, the shell unsets
# the function.
#
# Quirk found on: bash.
#
# Ref.: http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_29
# "If neither -f nor -v is specified, /name/ refers to a variable; if a
# variable by that name does not exist, it is unspecified whether a function
# by that name, if any, shall be unset."
#
# Moral of the story: for QRK_UNSETF compatibility, always provide either
# the -v or -f flag to 'unset',

unset -v _Msh_test

_Msh_test() {
	:
}

unset _Msh_test

if isset -f _Msh_test; then
	unset -f _Msh_test
	return 1
else
	return 0
fi
