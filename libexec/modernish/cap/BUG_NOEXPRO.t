#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_NOEXPRO: Cannot export read-only variables. (zsh 5.0.8 - 5.5.1)
! (
	_Msh_test=foo
	readonly _Msh_test
	export _Msh_test
) 2>/dev/null
