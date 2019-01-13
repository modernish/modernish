#! /shell/capability/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# ARITHPP: shell arith supports the ++ and -- unary operators.
# (Subshell needed because shells that don't support it exit.)
(	: $((i=0)) $((i++)) $((++i)) $((i--)) $((--i))
) 2>| /dev/null || return 1
