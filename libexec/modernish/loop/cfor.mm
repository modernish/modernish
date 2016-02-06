#! /module/for/moderni/sh
# An alias + internal function pair for a C-style 'for' loop.
# Usage:
# cfor '<initexpr>' '<testexpr>' '<loopexpr>'; do
#	<commands>
# done
#
# Each of the three arguments is a POSIX arithmethics expression as in $(( )).
# The <initexpr> is evaluated on the first iteration. The <loopexpr> is
# evaluated on every subsequent iteration. Then, on every iteration, the
# <testexpr> is run and the loop continues as long as it evaluates as true.
# As in 'let', operators like < and > must be appropriately shell-quoted to
# prevent their misevaluation by the shell. It is best to just enclose each
# argument in single quotes.
#
# For example, to count from 1 to 10:
#	cfor 'i=1' 'i<=10' 'i=i+1'; do
#		echo "$i"
#	done
#
# BUG:	'cfor' is not a true shell keyword, but an alias for two commands.
#	This makes it impossible to pipe data directly into a 'cfor' loop as
#	you would with native 'for', 'while' and 'until'.
#	Workaround: enclose the entire loop in { braces; }, for example:
#	cat file | { cfor i=1 'i<=5' i=i+1; do read L; print "$i: $L"; done; }
#
# TODO: a different syntax with two aliases, like with 'setlocal'...'endlocal',
#	would make a true shell block possible, but would require abandoning
#	the usual do ... done syntax. Is this preferable?

# The alias can work because aliases are expanded even before shell keywords
# like 'while' are parsed.
alias cfor='_Msh_cfor_init=y && while _Msh_doCfor'

# Main internal function. Not for direct use.
_Msh_doCfor() {
	if [ -n "${_Msh_cfor_init+y}" ]; then
		[ "$#" -eq 3 ] || die "cfor: 3 arguments expected, got $#" || return
		: "$(($1))"
		unset -v _Msh_cfor_init
	else
		: "$(($3))"
	fi
	return "$((!($2)))"
}
