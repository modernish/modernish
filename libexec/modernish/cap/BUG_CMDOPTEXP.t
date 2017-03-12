#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_CMDOPTEXP: the 'command' builtin does not recognise options if they
# result from expansions. (found in zsh)
push PATH
PATH=/dev/null	# disable PATH because '-p' is tried as an external command with this bug
_Msh_test=-p
! command "${_Msh_test}" true 2>/dev/null
pop --keepstatus PATH
