#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_CASEEMPT: an empty 'case' list on a single line is a syntax error.
#
# Bug found on: ksh93
# Ref.: https://github.com/ksh93/ksh/issues/177

! (eval 'case x in esac') 2>/dev/null
