#! /module/for/moderni/sh
# An alias + internal function pair for a C-style 'for' loop with arbitrary
# shell commands instead of arithmetic expressions.
#
# Usage:
#
# sfor '<initcommand>' '<testcommand>' '<loopcommand>'; do
#	<commands>
# done
#
# Each of the three arguments can be any command, even compound commands.
# The <initcommand> is run on the first iteration. The <loopcommand> is on
# every subsequent iteration. On every iteration, the <testcommand> is then
# run, and the loop continues as long as it exits successfully (status 0).
# These three commands MUST be appropriately shell-quoted to prevent their
# premature evaluation by the shell.
#
#!! BIG FAT SECURITY WARNING: Passing (any part of) the command arguments from
#!! variables is EXTREMELY STRONGLY DISCOURAGED, unless you (a) like to live
#!! dangerously, (b) really know what you are doing, and (c) can be 100% sure
#!! that the content of the variables can be trusted. We're talking 'eval';
#!! here be the code injection vulnerability dragons.
#!!    However, as long as you always fully enclose the commands in SINGLE
#!! QUOTES (even when referring to $variables), injecting shell grammar from
#!! variables is impossible and this is as secure as your standard 'while' or
#!! 'for' loop. So you really should just consider the single quotes around
#!! each of the three commands to be mandatory 'sfor' syntax.
#
# For the <initcommand> and <loopcommand>, any non-zero exit status is
# treated as a fatal error. For the <testcommand>, any exit status other
# than 0 or 1 is treated as a fatal error. Fatal errors abort your program.
#
# For example, to count from to 10 with traditional shell commands:
#	sfor 'i=1' '[ "$i" -le 10 ]' 'i=$((i+1))'; do
#		print "$i"
#	done
# or, with modernish commands:
#	sfor 'i=1' 'le i 10' 'inc i'; do
#		print "$i"
#	done
#
# BUG:	'sfor' is not a true shell keyword, but an alias for two commands.
#	This makes it impossible to pipe data directly into a 'sfor' loop as
#	you would with native 'for', 'while' and 'until'.
#	Workaround: enclose the entire loop in { braces; }, for example:
#	cat file | { sfor 'i=1' 'lt i 5' 'inc i'; do read L; print "$i: $L"; done; }

# The alias can work because aliases are expanded even before shell keywords
# like 'while' are parsed.
alias sfor='_Msh_sfor_init=y && while _Msh_doSfor'

# Main internal function. Not for direct use.
# Note from POSIX:
#	Since eval is not required to recognize the "--" end of options
#	delimiter, in cases where the argument(s) to eval might begin with
#	'-' it is recommended that the first argument is prefixed by a
#	string that will not alter the commands to be executed, such as a
#	<space> character.
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_19_16
_Msh_doSfor() {
	if [ -n "${_Msh_sfor_init+y}" ]; then
		[ "$#" -eq 3 ] || die "sfor: 3 arguments expected, got $#" || return
		eval " $1" || die 'sfor: init command failed' || return
		unset -v _Msh_sfor_init
	else
		eval " $3" || die 'sfor: loop command failed' || return
	fi
	eval " $2" && return
	[ "$?" -gt 1 ] && die "sfor: test command failed"
}
