#! /shell/warning/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# WRN_EREBOUNDS: If this is detected, the 'str ematch' function is using
# an 'awk' implementation whose regular expression engine does not support
# POSIX-standard interval expressions, a.k.a repetition expressions,
# a.k.a. bounds. This means that something like str ematch 'aaa' 'a{3}'
# will not match. As of 2019, the system versions of 'awk' on current *BSD
# systems lack support for interval expressions (which has already been
# fixed upstream <https://github.com/onetrueawk/awk/pull/30>,
# but it will take years for the fix to trickle down to the installed
# base). To fix this limitation, either install an updated 'awk' or GNU
# 'gawk' somewhere in your $PATH, or run modernish on a shell that
# internally supports extended regular expressions (bash, ksh93, yash, zsh).

str ematch 'aaa' '^a+$' && not str ematch 'aaa' '^a{3}$'
