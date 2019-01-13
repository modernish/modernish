#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_CMDPV: 'command -pv' is not usable:
# - it does not find builtins. ({pd,m}ksh)
# - it won't accept the '-p' and '-v' options together. (zsh < 5.3)
# - it ignores the '-p' option altogether. (bash 3.2)

push PATH
PATH=/dev/null
! { command -pv : && command -pv ls; } >/dev/null 2>&1
pop --keepstatus PATH
