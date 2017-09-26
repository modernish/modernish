#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_ISSETLOOP: On AT&T ksh93, expansions like ${var+set} and ${var+:nonempty)
# remain static when used within a 'for', 'while' or 'until' loop; the
# expansions don't change along with the state of the variable, so they cannot
# be used to check whether a variable is set and/or empty within a loop if the
# state of that variable may change in the course of the loop.
#
# Bizarrely, this bug only applies to ${var+set} and ${var:+nonempty}.
# Something like ${var-unset} and ${var:-empty} works fine.
#
# (found in AT&T ksh93, release and beta versions)

# _Msh_test is guaranteed to be unset on entry
push _Msh_i _Msh_r
_Msh_r=
for _Msh_i in 1 2 3 4; do
	case ${_Msh_test+s} in
	( s )	_Msh_r=${_Msh_r}s; unset -v _Msh_test ;;
	( '' )	_Msh_r=${_Msh_r}u; _Msh_test= ;;
	esac
done
case ${_Msh_r} in
(uuuu)	setstatus 0 ;;
(usus)	setstatus 1 ;;
(*)	echo "BUG_ISSETLOOP.t: Undiscovered bug with \${var+test}!" >&2
	setstatus 2 ;;
esac
pop --keepstatus _Msh_i _Msh_r
