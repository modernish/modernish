#! /helper/script/for/moderni/sh
IFS=''; set -fCu  # safe mode

# This is a helper script called by the '-ask' primary of 'LOOP find'.
#
# --- begin license ---
# Copyright (c) 2020 Martijn Dekker <martijn@inlv.org>, Groningen, Netherlands
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

trap 'trap - PIPE; kill -s PIPE $PPID $$' PIPE

interrupt_find() {
	kill -s PIPE $$		# this will also kill our $PPID (the 'find' utility) through the trap
	kill -s TERM $PPID $$	# SIGPIPE is ignored: loop/find.mm will OK this if WRN_NOSIGPIPE was detected, or die()
	DIE "signals ignored"	# both SIGPIPE and SIGTERM are ignored: fatal; loop/find.mm will die()
}

DIE() {
	echo "LOOP find: $@" >&2
	kill -s KILL $PPID $$
}

PATH=${_loop_PATH}

case $# in
( 2 )	;;
( * )	echo "die 'LOOP find: internal error'" >&8 || DIE "internal error"
	interrupt_find ;;
esac

# Since the question won't have been an argument consisting of only {},
# it is implementation-defined whether the 'find' utility will already have
# replaced the occurrences of {} in the question. If not, do it here.
pattern='{}'
buffer=$1
question=''
while case $buffer in (*"$pattern"*);; (*) break;; esac; do
        question=$question${buffer%%"$pattern"*}$2
        buffer=${buffer#*"$pattern"}
done
question=$question$buffer

# Get regex for affirmative answer in current locale.
yesexpr=$(locale yesexpr 2>/dev/null)
case $yesexpr in
( '' )	yesexpr='^[yY]' ;;
( * )	case yesexpr in
	( \"*\" ) yesexpr=${yesexpr#?}; yesexpr=${yesexpr%?} ;;
	esac ;;
esac

# Ask the question. End with an exit status matching the answer.
printf '%s ' $question
IFS=' 	' read -r answer 2>/dev/null || { echo; interrupt_find; }
printf '%s\n' $answer | grep -Eq -- $yesexpr
