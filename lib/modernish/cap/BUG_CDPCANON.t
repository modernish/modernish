#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_CDPCANON: 'cd -P' (and hence also modernish 'chdir') does not
# correctly canonicalise/normalise a directory path that starts with three
# or more slashses; it reduces these to two slases instead of one in $PWD.
#
# Bug found on: zsh <= 5.7.1
# Ref.: http://www.zsh.org/mla/workers/2020/msg00192.html

(
    command cd -P /////dev
    str eq "$PWD" //dev
)
