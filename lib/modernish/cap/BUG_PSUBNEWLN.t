#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PSUBNEWLN: Due to a bug in the parser, parameter substitutions
# spread over more than one line cause a syntax error.
# Ref.: https://www.spinics.net/lists/dash/msg01430.html
# Workaround: instead of a literal newline, use "$CCn".
# (found in dash <= 0.5.9.1 and Busybox ash <= 1.28.1)

( eval ': ${$+
}' ) 2>/dev/null && return 1 || return 0
