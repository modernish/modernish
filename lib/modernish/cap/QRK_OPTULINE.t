#! /shell/quirk/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# QRK_OPTULINE: long-form option names are insensitive to underline characters.
# Quirk found on: ksh93, yash, zsh.

(set +o all__ex_port +o nou_nset +o x_trace) 2>/dev/null || return 1
