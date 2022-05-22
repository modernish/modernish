#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_CSUBLNCONT: Backslash line continuation is broken within
# modern-form $(command substitutions)
#
# Bug found on: ksh93, all versions before 93u+m 2022-05-21
# Ref.: https://github.com/ksh93/ksh/issues/367

case $(echo A B\
C) in
( 'A BC' )  return 1 ;;
esac
