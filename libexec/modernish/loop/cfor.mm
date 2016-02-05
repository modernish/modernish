#! /module/for/moderni/sh
# An alias + internal function pair for a C-style 'for' loop.
# Usage:
# cfor '<initcommand>' '<testcommand>' '<loopcommand>'; do
#	<commands>
# done
#
# Each of the three arguments can be any command, even compound commands.
# The <initcommand> is run on the first iteration. The <loopcommand> is run
# on every subsequent iteration. Then, on every iteration, the <testcommand>
# is run and the loop continues as long as it exits successfully. These
# commands must be appropriately shell-quoted to prevent their premature
# evaluation by the shell.
#
# For example, to count from to 10 with traditional shell commands:
#	cfor 'i=1' '[ $i -le 10 ]' 'i=$((i+1))'; do
#		echo $i
#	done
# or, with modernish commands:
#	cfor 'i=1' 'le $i 10' 'inc i'; do
#		echo $i
#	done

# The alias can work because aliases are expanded even before shell keywords
# like 'while' are parsed.
alias cfor='_Msh_cfor_init=y && while _Msh_doCfor'

# Main internal function. Not for direct use.
_Msh_doCfor() {
	if [ -n "${_Msh_cfor_init+y}" ]; then
		[ $# -eq 3 ] || die "cfor: 3 arguments expected, got $#" || return
		eval "$1" || die 'cfor: init command failed' || return
		unset -v _Msh_cfor_init
	else
		eval "$3" || die 'cfor: loop command failed' || return
	fi
	eval "$2"
}
