#! /module/for/moderni/sh
\command unalias eq ge gt le lt ne 2>/dev/null

# modernish var/arith/cmp

# --- Integer number arithmetic test shortcuts. ---
# These have the sames name as their 'test'/'[' option equivalents. Unlike
# with 'test', the arguments are shell integer arith expressions, which can
# be anything from simple numbers to complex expressions. As with $(( )),
# variable names are expanded to their values even without the '$'.
#
# Portability note: bash, ksh and zsh do recursive evaluation of variable
# names (where a variable can contain the name of another variable, and so
# forth), but that is non-standard and unportable.
#
# Function:		Returns successfully if:
# --------		-----------------------
# eq <expr> <expr>	the two expressions evaluate to the same number
# ne <expr> <expr>	the two expressions evaluate to different numbers
# lt <expr> <expr>	the 1st expr evaluates to a smaller number than the 2nd
# le <expr> <expr>	the 1st expr eval's to smaller than or equal to the 2nd
# gt <expr> <expr>	the 1st expr evaluates to a greater number than the 2nd
# ge <expr> <expr>	the 1st expr eval's to greater than or equal to the 2nd
#
# Example:
# if eq 2+2 4; then echo 'freedom granted; all else follows'; fi
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

# Notes:
#
# The arith operator itself does sufficient validation on all shells, though
# error messages are not always very clear.
#
# As a performance hack, the functions below abuse this arith validation in
# combination with parameter substitution to check for excess arguments, by
# injecting a guaranteed-to-be-invalid value (starting with an escaped '\') in
# case of excess arguments. According to my tests, this is completely reliable
# in every shell, and causes no noticeable performance reduction. Not only
# that, many shells (not zsh or yash) helpfully insert the invalid value into
# its own error message, so we can add our own message ('excess arguments') to
# be passed on.
#
# Shells exit on arith evaluation errors, so the usual "|| die" is ineffective
# and we can't terminate the program properly from a subshell. I have made the
# choice that the performance gain is worth it in this instance.

if thisshellhas ARITHCMD; then
	eval '
	eq() { (((${1?eq: needs 2 arguments})==(${2?eq: needs 2 arguments})${3+\\[ eq: excess arguments ]})); }
	ne() { (((${1?ne: needs 2 arguments})!=(${2?ne: needs 2 arguments})${3+\\[ ne: excess arguments ]})); }
	lt() { (((${1?lt: needs 2 arguments})<(${2?lt: needs 2 arguments})${3+\\[ lt: excess arguments ]})); }
	le() { (((${1?le: needs 2 arguments})<=(${2?le: needs 2 arguments})${3+\\[ le: excess arguments ]})); }
	gt() { (((${1?gt: needs 2 arguments})>(${2?gt: needs 2 arguments})${3+\\[ gt: excess arguments ]})); }
	ge() { (((${1?ge: needs 2 arguments})>=(${2?ge: needs 2 arguments})${3+\\[ ge: excess arguments ]})); }
	'
else
	# Note: the inversion of comparison operators is NOT a bug! POSIX arith is
	# based on the C language, so uses 1 for true and 0 for false, whereas the
	# shell language itself does the inverse. The fastest way to invert the result
	# code is to invert the operators.
	eq() { return "$(((${1?eq: needs 2 arguments})!=(${2?eq: needs 2 arguments})${3+\\[ eq: excess arguments ]}))"; }
	ne() { return "$(((${1?ne: needs 2 arguments})==(${2?ne: needs 2 arguments})${3+\\[ ne: excess arguments ]}))"; }
	lt() { return "$(((${1?lt: needs 2 arguments})>=(${2?lt: needs 2 arguments})${3+\\[ lt: excess arguments ]}))"; }
	le() { return "$(((${1?le: needs 2 arguments})>(${2?le: needs 2 arguments})${3+\\[ le: excess arguments ]}))"; }
	gt() { return "$(((${1?gt: needs 2 arguments})<=(${2?gt: needs 2 arguments})${3+\\[ gt: excess arguments ]}))"; }
	ge() { return "$(((${1?ge: needs 2 arguments})<(${2?ge: needs 2 arguments})${3+\\[ ge: excess arguments ]}))"; }
fi

if thisshellhas ROFUNC; then
	readonly -f eq ne lt le gt ge
fi
