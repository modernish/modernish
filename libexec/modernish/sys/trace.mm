#! /module/for/moderni/sh

# Using modernish library functions make 'set -x' (-o xtrace) output very
# cluttered. This module provides a way around that problem: instead of
# using 'set -x', you can trace specific commands by prefixing them with the
# word "trace". This works only for simple commands, not shell grammatical
# constructs.
#
# There are a few enhancements to standard POSIX 'set -x':
#	- Commands are properly shell-quoted so you can tell one argument
#	  from the next even if arguments include whitespace.
#	- On ANSI-type terminals, the command is highlighted.
#
# --- begin license ---
# Copyright (c) 2016 Martijn Dekker <martijn@inlv.org>, Groningen, Netherlands
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

# File descriptor #9 is used for tracing.
# This way, scripts can redirect standard error without affecting tracing.
exec 9>&2

if	is onterminal 9 &&
	isset TERM &&
	ematch "$TERM" '(^ansi|^xterm|^linux|^vt[1-5][0-9][0-9]|^cygwin)'
then	# highlight in blue
	trace() {
		storeparams _Msh_trace_C	# shellquote and store
		echo "$CCe[1;34m+ ${_Msh_trace_C}$CCe[0m" 1>&9
		unset -v _Msh_trace_C
		"$@"
	}
else	# default
	trace() {
		storeparams _Msh_trace_C
		echo "+ ${_Msh_trace_C}" 1>&9
		unset -v _Msh_trace_C
		"$@"
	}
fi
