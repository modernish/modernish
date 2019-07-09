#! /module/for/moderni/sh
\command unalias dec div inc mod mult ndiv 2>/dev/null

# modernish var/arith/ops
#
# --- Integer arithmetic operator shortcuts. ---
# Usage: inc/dec/mult/div/ndiv/mod <varname> [ <expr> ]
# Increase/decrease/multiply/divide/modulus the value of the variable by the
# result of the integer arithmetic expression <expr>. Default for <expr> is
# 1 for 'inc' and 'dec', 2 for 'mult' and 'div', 256 for 'mod'.
#
# ndiv: always round down, even for negative numbers.
# Usage: ndiv <varname> [ <expr> ]
# ndiv is like div, but always returns the integer on or before
# $((varname / expr)), even for negative numbers. Standard shell
# arith just chops off the digits after the decimal point, which
# is not ok for negative. (The idea is from wide_strftime.sh by
# Stéphane Chazelas: http://stchaz.free.fr)
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

# The basic operations.
# (Note: ARITHCMD versions would not be exactly equivalent as ((...)) returns
# an exit status of 1 if the result of the arithmetic expression is 0.)
inc()  { : "$((${1?inc: needs 1 or 2 arguments}+=(${2-1})${3+\\$CCn[ inc: excess arguments ]}))"; }
dec()  { : "$((${1?dec: needs 1 or 2 arguments}-=(${2-1})${3+\\$CCn[ dec: excess arguments ]}))"; }
mult() { : "$((${1?mult: needs 1 or 2 arguments}*=(${2-2})${3+\\$CCn[ mult: excess arguments ]}))"; }
div()  { : "$((${1?div: needs 1 or 2 arguments}/=(${2-2})${3+\\$CCn[ div: excess arguments ]}))"; }
mod()  { : "$((${1?mod: needs 1 or 2 arguments}%=(${2-256})${3+\\$CCn[ mod: excess arguments ]}))"; }

# Division with correct rounding down for negative numbers.
# Since we need to access the value of $2 several times, pre-evaluate
# the expression to avoid it being evaluated multiple times
# (otherwise things like additive assignment would wreak havoc).
ndiv() {
	set -- "${1?ndiv: needs 1 or 2 arguments}" "$(((${2-2})${3+\\$CCn[ ndiv: excess arguments ]}))"
	: "$(($1 = (($1/$2)*$2 > $1) ? $1/$2-1 : $1/$2))"
}

if thisshellhas ROFUNC; then
	readonly -f inc dec mult div mod ndiv
fi
