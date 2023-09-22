#! /helper/script/for/moderni/sh
IFS=''; set -fCu  # safe mode

# This is a helper script called by the '-exec' primary of 'find' in the
# var/loop/find module when -ok or -okdir is used, i.e interactive iterations.
# It is based on find.sh, but only takes 1 argument. After writing that
# argument as an assignment for the main shell to eval, this script stops its
# own execution with SIGSTOP before terminating upon receiving SIGCONT, so
# 'find' will not ask the next question before the current iteration completes.
#
# --- begin license ---
# Copyright (c) 2019 Martijn Dekker <martijn@inlv.org>
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

# If the pipe is broken, the -exec'ed shell will get SIGPIPE but the 'find' utility itself won't.
# To avoid 'find' going haywire, our -exec'ed shell must trap SIGPIPE and kill its parent PID, which
# is the 'find' utility. Also add a fallback check for I/O error in 'put', in case SIGPIPE is ignored.

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

# Check that either the variable or the xargs option was exported to here, but not both.

case ${_loop_PATH+A}${_loop_AUX+O}${_loop_V+K}${_loop_xargs+K} in
( AOK )	;;
( * )	echo "die 'LOOP find: internal error'" >&8 || DIE "internal error"
	interrupt_find ;;
esac

PATH=${_loop_PATH}

# Use modernish shell-quoting (via awk) to guarantee one loop iteration
# command per line, so the main shell can safely 'read -r' and 'eval' any
# possible file names from the FIFO.
#
# Pause this -exec'ed process with SIGSTOP to avoid 'find' displaying
# the next confirmation prompt before the loop iteration completes.

awk -v _loop_SIGCONT=$$ -f ${_loop_AUX}/find.awk -- "$@" >&8 &
kill -s STOP $$	# freeze until SIGCONT
wait $!		# obtain awk's exit status
e=$?
case $e in
( 0 )	;;
( 126 )	DIE "system error: awk could not be executed" ;;
( 127 )	DIE "system error: awk could not be found" ;;
( 129 | 1[3-9]? | [!1]?? | ????* )
	sig=$(kill -l $e 2>/dev/null)
	sig=${sig#[sS][iI][gG]}
	case $sig in
	( [pP][iI][pP][eE] )
		interrupt_find ;;  # propagate SIGPIPE upwards
	( '' | [0-9]* )
		DIE "system error: awk exited with status $e" ;;
	( * )	DIE "system error: awk was killed by SIG$sig" ;;
	esac ;;
( * )	# other nonzero exit status: presume write error from awk
	interrupt_find ;;
esac
