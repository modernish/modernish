#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PSUBPAREN: Parameter substitutions where the word to substitute contains
# parentheses wrongly cause a "bad substitution" error. (pdksh)
! ( : "${var+(word)}" ) 2>|/dev/null
