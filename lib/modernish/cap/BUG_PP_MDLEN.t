#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PP_MDLEN: For ${#x} expansions where x >= 10, only the first digit of
# the positional parameter number is considered, e.g. ${#10}, ${#12}, ${#123}
# are all parsed as if they are ${#1}. Then, string parsing is aborted so that
# further characters or expansions, if any, are lost.
# Bug found in: dash 0.5.11 - 0.5.11.4 (fixed in dash 0.5.11.5)
push -u
set +u _1_
case ${#13},${#234},${#1},OK in
( 0,0,3,OK ) pop -u; return 1 ;;
esac
pop -u
