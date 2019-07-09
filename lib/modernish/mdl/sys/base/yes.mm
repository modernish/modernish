#! /module/for/moderni/sh
\command unalias yes 2>/dev/null

# modernish sys/base/yes
#
# Output a string (default: 'y') repeatedly until killed.
# Useful to automate a command requiring interactive confirmation,
# e.g.: yes | some_command_that_asks_for_confirmation
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

yes() (
	case $# in
	( 0 )	_Msh_buf=y$CCn ;;
	( * )	IFS=' '; _Msh_buf="$*$CCn" ;;
	esac
	export _Msh_buf "PATH=$DEFPATH"
	unset -f awk	# QRK_EXECFNBI compat
	exec awk 'BEGIN {
		ORS=""
		b=ENVIRON["_Msh_buf"];
		while (length(b) < 8192)
			b=(b)(b);
		while(1)
			print(b);
	}'
)

if thisshellhas ROFUNC; then
	readonly -f yes
fi
