#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_TESTRMPAR: zsh: in binary operators with 'test'/'[', if the first
# argument starts with '(' and the last with ')', both the first and the last
# argument are completely removed, leaving only the operator, and the result of
# the operation is incorrectly true because the operator is incorrectly parsed
# as a non-empty string, as in [ "$v" ]. This applies to all the binary
# operators, including string comparisons and file comparisons.
# Ref.: http://www.zsh.org/mla/workers/2015/msg03275.html
# * Workarounds for string comprisons:
#   Instead of [ "$foo" = "$bar" ],
#   - either use modernish: str eq "$foo" "$bar"
#   - or do what POSIX recommends anyway and start the strings with a protector
#     character when comparing arbitrary data: [ "X$foo" = "X$bar" ]
# * Workarounds for file comparisons ([ "$1" -nt/-ot/-ef "$2" ]):
#   None known, except to use '[[' instead.
# * The bug also applies to arithmetic comparison ([ "$1" -eq "$2" ], etc.)
#   but this is only relevant for invalid values; still, '[' will produce
#   false positives if erroneous data is fed according to this bug pattern,
#   for example:   x='(1'; y=')2'; [ "$x" -eq "$y" ]   will yield true.

PATH=$DEFPATH command test '(a' = ')b' 2>/dev/null || return 1
