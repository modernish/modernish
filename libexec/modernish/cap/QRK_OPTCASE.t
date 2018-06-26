#! /shell/quirk/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# QRK_OPTCASE: long-form option names are case insensitive.
# Quirk found on: yash, zsh.

(set +o AllExPort +o NOUNSET +o xTrace) 2>/dev/null || return 1
