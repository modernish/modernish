#! /shell/quirk/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# QRK_OPTDASH: long-form option names are insensitive to dash (minus) characters.
# Quirk found on: ksh93, yash.

(set +o all--ex-port +o nou-nset +o x-trace) 2>/dev/null || return 1
