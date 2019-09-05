#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_REDIRPOS: Buggy behaviour occurs on zsh if a redirection is
# positioned in between two variable assignments in the same command.
#
# - On zsh 5.0.7 and 5.0.8, a parse error is thrown.
#
# - On zsh 5.1 to 5.4.2, anything following the redirection (other
#   assignments or a command) is silently ignored.
#
# Ref.: zsh-workers 42105: http://www.zsh.org/mla/workers/2017/msg01769.html

! (eval '_Msh_test=foo >/dev/null _Msh_test=bar' && str eq "${_Msh_test}" "bar") 2>/dev/null
