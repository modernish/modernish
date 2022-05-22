#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_CSUBBTQUOT: Double quotes within a backtick-style command substitution
# within double quotes cause a syntax error.
#
# Bug found on: ksh93, all versions before 93u+m 2022-05-20
# Ref.: https://github.com/ksh93/ksh/issues/352

! (eval '_Msh_test="`: "("`"') 2>/dev/null
