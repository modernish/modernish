#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_CSCMTQUOT: unbalanced single and double quotes and backticks in comments
# within command substitutions cause obscure and hard-to-trace syntax errors
# later on in the script. (ksh88; pdksh, incl. {Open,Net}BSD ksh; bash 2.05b)
! ( eval ': $( : # dummy comment with unbalanced quote"
	)' ) 2>|/dev/null
