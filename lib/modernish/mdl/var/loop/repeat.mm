#! /module/for/moderni/sh
\command unalias _loopgen_repeat 2>/dev/null
#
# modernish var/loop/repeat
#
# A simple repeat loop. Execute <commands> <expr> times.
# The <expr> is evaluated as an arithmetic expression once upon loop entry.
#
#	LOOP repeat <expr>; DO
#		<commands>
#	DONE
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

use var/loop

_loopgen_repeat() {
	let "$# == 1" || _loop_die "expected 1 argument, got $#"
	case +$1 in
	( *[!_$ASCIIALNUM]_loop_* | *[!_$ASCIIALNUM]_Msh_* )
		_loop_die "cannot use _Msh_* or _loop_* internal namespace" ;;
	esac
	_loop_expr=$1

	# Validate the expression, determining the number of repeats.
	# Since non-builtin modernish 'let' will exit on error, trap EXIT.
	command trap '_loop_die "invalid arithmetic expression: ${_loop_expr}"' 0	# BUG_TRAPEXIT compat
	let "_loop_R = (${_loop_expr})" || exit
	command trap - 0

	# An arithmetic expression may change variables, so evaluate it once in the main shell.
	shellquote _loop_expr
	if let "_loop_R > 0"; then
		put "let ${_loop_expr} || :" >&8
	else
		putln "let ${_loop_expr} && ! :" >&8
		return
	fi

	# This loop has no variable or anything else to modify,
	# so the iteration commands are empty lines.
	_Msh_i=0
	while let "(_Msh_i += 1) <= _loop_R"; do
		putln || exit
	done >&8 2>/dev/null
}

if thisshellhas ROFUNC; then
	readonly -f _loopgen_repeat
fi
