#! /shell/capability/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# ARITHFOR: ksh93/C-style arithmetic 'for' loops of the form
#	for ((exp1; exp2; exp3)) do commands; done
# Supported by bash, zsh, AT&T ksh.

(eval 'for ((;0;)) do :; done' 2>/dev/null) || return 1
