#! /shell/capability/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# QRK_OPTNOPRFX: long-form shell option names use a dynamic 'no-' prefix
# for all options (including POSIX ones). For instance, 'glob' is the
# opposite of 'noglob', and 'nonotify' is the opposite of 'notify'.
#
# This quirk is known to be present on: AT&T ksh93; yash; zsh

(set +a; set +o noallexport; isset -a) 2>/dev/null || return 1
