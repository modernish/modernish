#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_ALSUBSH: Aliases defined within subshells leak upwards to the main shell.
# (found in ksh93 versions "M 1993-12-28 s+", "JM 93t+ 2010-03-05")
( alias BUG_ALSUBSH=true )
alias BUG_ALSUBSH >|/dev/null 2>&1 || return 1
