#! /module/for/moderni/sh
\command unalias sortsafter sortsbefore 2>/dev/null

# var/string/sortstest
# 
# sortsbefore, sortsafter: lexical comparison.

# For lexical comparison, unfortunately [ '<' and '>' ] are not POSIX, but the standards-compliant
# way requires the external 'expr' utility. So let's see what this particular shell supports and
# fall back on 'expr', making sure that it works even if the arguments contain newline characters.
#
#	(Unfortunately, dealing with empty removal as in identic() is impossible, because if there
#	is only one removed empty argument, then you cannot tell whether it was the first or second
#	argument, so it's impossible to tell how it sorts. So if there is the possibility of empty
#	variables, they must always be quoted, even under 'use safe'.)
#
# --- begin license ---
# Copyright (c) 2019 Martijn Dekker <martijn@inlv.org>, Groningen, Netherlands
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
#
# ...	If we're running on bash, ksh or zsh:
if thisshellhas DBLBRACKET
then
	eval 'sortsbefore() {
		case $# in
		( 2 )	[[ $1 < $2 ]] ;;
		( * )	_Msh_dieArgs sortsbefore "$#" 2 ;;
		esac
	}
	sortsafter() {
		case $# in
		( 2 )	[[ $1 > $2 ]] ;;
		( * )	_Msh_dieArgs sortsafter "$#" 2 ;;
		esac
	}'
# ...	Try to fall back to builtin '['/'test' non-standard feature.
#	Thankfully, '<' and '>' are pretty widely supported for this builtin. Unlike with [[ ]],
#	we need to quote everything. (Note that test() is a 'test' hardened in bin/modernish.)
elif thisshellhas --bi=test \
&& PATH=$DEFPATH command test "a${CCn}b" '<' "a${CCn}bb" 2>/dev/null \
&& PATH=$DEFPATH command test "a${CCn}bb" '>' "a${CCn}b" 2>/dev/null
then
	sortsbefore() {
		case $# in
		( 2 )	test "X$1" '<' "X$2" ;;
		( * )	_Msh_dieArgs sortsbefore "$#" 2 ;;
		esac
	}
	sortsafter() {
		case $# in
		( 2 )	test "X$1" '>' "X$2" ;;
		( * )	_Msh_dieArgs sortsafter "$#" 2 ;;
		esac
	}
# ...	Fall back to the POSIX way with the external expr(1) utility.
else
	sortsbefore() {
		case $# in
		( 2 )	PATH=$DEFPATH command expr "X$1" '<' "X$2" >/dev/null \
			|| { let "$? > 1" && die "sortsbefore: 'expr' failed"; } ;;
		( * )	_Msh_dieArgs sortsbefore "$#" 2 ;;
		esac
	}
	sortsafter() {
		case $# in
		( 2 )	PATH=$DEFPATH command expr "X$1" '>' "X$2" >/dev/null \
			|| { let "$? > 1" && die "sortsafter: 'expr' failed"; } ;;
		( * )	_Msh_dieArgs sortsafter "$#" 2 ;;
		esac
	}
fi
