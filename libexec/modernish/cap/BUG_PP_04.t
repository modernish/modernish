#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PP_04: Assigning the positional parameters to a variable using
# ${var=$*} doesn't work as expected for one or more settings of IFS.
# (POSIX leaves ${var=$@} undefined, so we don't test that.)
# Found on: mksh, bash 2, bash 4.3.39
#
# Note: an easy way to circumvent this bug is to always quote either the
# $* within the expansion or the expansion as a whole, i.e.: ${var="$*"}
# or "${var=$*}". This works correctly on all shells known to run modernish.
#
# See also BUG_PP_04_S (assignment is correct but expansion is wrongly split).

set -- one 'two three' four
push IFS _Msh_tV
if {
	IFS=" $CCt$CCn"
	unset -v _Msh_tV
	: ${_Msh_tV=$*}
	! identic "${_Msh_tV}" "one two three four"
} || {
	IFS=
	unset -v _Msh_tV
	: ${_Msh_tV=$*}
	! identic "${_Msh_tV}" "onetwo threefour"
} || {
	IFS=XYZ
	unset -v _Msh_tV
	: ${_Msh_tV=$*}
	! identic "${_Msh_tV}" "oneXtwo threeXfour"
} || {
	unset -v IFS
	unset -v _Msh_tV
	: ${_Msh_tV=$*}
	! identic "${_Msh_tV}" "one two three four"
}; then
	pop IFS _Msh_tV
	return 0	# got bug
else
	pop IFS _Msh_tV
	return 1
fi
