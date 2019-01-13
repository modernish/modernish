#! /shell/capability/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# HERESTR: shell supports here-strings, a special kind of here-document.

# The here-string syntax produces a syntax error on shells that don't
# support it, so the feature test is simple, though it comes at the cost of
# forking a subshell.
( eval ': <<<a' ) 2>/dev/null || return 1
