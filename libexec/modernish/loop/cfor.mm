#! /module/for/moderni/sh
unalias _Msh_doCfor
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
#	cfor 'i=1' 'i<=10' 'i+=1'; do
#		echo "$i"
#	done
#
# BUG:	'cfor' is not a true shell keyword, but an alias for two commands.
#	This makes it impossible to pipe data directly into a 'cfor' loop as
#	you would with native 'for', 'while' and 'until'.
#	Workaround: enclose the entire loop in { braces; }, for example:
#	cat file | { cfor i=1 'i<=5' i+=1; do read L; putln "$i: $L"; done; }
#
# --- begin license ---
# Copyright (c) 2018 Martijn Dekker <martijn@inlv.org>, Groningen, Netherlands
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# --- end license ---

# The alias can work because aliases are expanded even before shell keywords
# like 'while' are parsed.
alias cfor='_Msh_cfor_init=y && while _Msh_doCfor'

# Main internal function. Not for direct use.
if thisshellhas ARITHCMD; then
	_Msh_doCfor() {
		case ${#}${_Msh_cfor_init+y} in
		( 3 )	(($3)) ;;
		( 3y )	(($1))
			unset -v _Msh_cfor_init ;;
		( * )	die "cfor: 3 arguments expected, got $#" || return ;;
		esac
		(($2))
	}
else
	_Msh_doCfor() {
		case ${#}${_Msh_cfor_init+y} in
		( 3 )	: "$(($3))" ;;
		( 3y )	: "$(($1))"
			unset -v _Msh_cfor_init ;;
		( * )	die "cfor: 3 arguments expected, got $#" || return ;;
		esac
		return "$((!($2)))"
	}
fi
