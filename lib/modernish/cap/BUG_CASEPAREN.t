#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_CASEPAREN: 'case' patterns without an opening parenthesis
# (i.e. with only an unbalanced closing parenthesis) are misparsed
# as a syntax error within command substitutions of the form $( ).
#
# Bug found on: bash 3.2

! (eval ': $(case x in y) : ;; esac)') 2>/dev/null
