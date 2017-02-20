#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PP_04_S: When IFS is null (empty), the result of a substitution
# containing an default assignment to unquoted $* or $@ is incorrectly
# field-split on spaces (no field splitting should occur with null IFS).
#
# Found on: bash 4.2, 4.3
#
# This bug is related to BUG_PP_04, which also tests ${var=$*}, but in that
# bug, the expansion incorrectly generates multiple fields without
# splitting, corrupting the scalar assignment in the process. In BUG_PP_04_S,
# the scalar assignment is executed correctly and fields are generated
# correctly, but the result is split incorrectly.

set -- one 'two three' four
push IFS
IFS=
set -- ${_Msh_test=$*}
pop IFS
case ${_Msh_test},$#,${1-},${2-} in
( "onetwo threefour,1,onetwo threefour," ) return 1 ;;
( "onetwo threefour,2,onetwo,threefour" )  ;;  # got bug
( * )	if thisshellhas BUG_PP_04; then
		# We expect the assignment to go wrong, so test only the expansion.
		case $#,${1-},${2-} in
		( "2,onetwo,threefour" )  ;;	# got bug
		( * )	return 1 ;;		# no further testing; got some variant of BUG_PP_04 breakage
		esac
	else
		echo 'BUG_PP_04_S: internal error: undiscovered bug with ${_Msh_test=$*}'
		return 2
	fi ;;
esac
