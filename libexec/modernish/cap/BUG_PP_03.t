#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PP_03: Assigning the positional parameters to a variable using
# var=$* or var="$*" doesn't work as expected.
# Eight possible variants of BUG_PP_03 are detected for both var=$* and
# var="$*" and four different settings of IFS. Run `modernish --test` to
# find out the specific variant of this bug on your shell (if any).
# (POSIX leaves var=$@, etc. undefined, so we don't test that.)
# Found on: zsh 5.2, 5.3, 5.3.1 (sh mode), pdksh, bash 2

set -- one 'two three' four
push IFS _Msh_tQ
{
	IFS=" $CCt$CCn"
	_Msh_test=$*
	_Msh_tQ="$*"
	! identic "${_Msh_test}|${_Msh_tQ}" "one two three four|one two three four"
} || {
	IFS=
	_Msh_test=$*
	_Msh_tQ="$*"
	! identic "${_Msh_test}|${_Msh_tQ}" "onetwo threefour|onetwo threefour"
} || {
	IFS=XYZ
	_Msh_test=$*
	_Msh_tQ="$*"
	! identic "${_Msh_test}|${_Msh_tQ}" "oneXtwo threeXfour|oneXtwo threeXfour"
} || {
	unset -v IFS
	_Msh_test=$*
	_Msh_tQ="$*"
	! identic "${_Msh_test}|${_Msh_tQ}" "one two three four|one two three four"
}
pop --keepstatus IFS _Msh_tQ
