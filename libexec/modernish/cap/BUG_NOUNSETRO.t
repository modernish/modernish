#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_NOUNSETRO: Cannot freeze variables as readonly in an unset state.
# This bug in zsh < 5.0.8 makes the 'readonly' command set them to the
# empty string instead. For BUG_NOUNSETRO compatibility, modernish library
# code should not depend on the unset status of read-only variables.
(
	unset -v _Msh_testNOUNSETRO
	readonly _Msh_testNOUNSETRO
	isset -v _Msh_testNOUNSETRO
)
