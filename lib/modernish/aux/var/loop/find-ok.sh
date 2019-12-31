#! /helper/script/for/moderni/sh
#! use safe -k
#! use var/shellquote

# This is a helper script called by the '-exec' primary of 'find' in the
# var/loop/find module when -ok or -okdir is used, i.e interactive iterations.
# It is based on find.sh, but only takes 1 argument. After writing that
# argument as an assignment for the main shell to eval, this script stops its
# own execution with SIGSTOP before terminating upon receiving SIGCONT, so
# 'find' will not ask the next question before the current iteration completes.
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

# If the pipe is broken, the -exec'ed shell will get SIGPIPE but the 'find' utility itself won't.
# To avoid 'find' going haywire, our -exec'ed shell must trap SIGPIPE and kill its parent PID, which
# is the 'find' utility. Also add a fallback check for I/O error in 'put', in case SIGPIPE is ignored.

trap 'trap - PIPE; kill -s PIPE $PPID $$' PIPE

DIE() {
	kill -s PIPE $$		# this will also kill our $PPID (the 'find' utility) through the trap
	kill -s TERM $PPID $$	# SIGPIPE is ignored: loop/find.mm will OK this if WRN_NOSIGPIPE was detected, or die()
	kill -s KILL $PPID $$	# both SIGPIPE and SIGTERM are ignored: fatal; loop/find.mm will die()
}

# Check that the variable was exported to here.

case ${MSH_VERSION+O}${_loop_V+K} in
( OK )	;;
( * )	case ${MSH_VERSION+m} in
	( '' )	echo "find-ok.sh cannot be called directly." >&2
		exit 128 ;;
	esac
	putln "die 'LOOP find: internal error'" >&8 || kill -s KILL $PPID $$
	DIE ;;
esac

# Use modernish shellquote() to guarantee one shell-quoted loop iteration
# command per line, so the main shell can safely 'read -r' and 'eval' any
# possible file names from the FIFO.
#
# Then pause this -exec'ed process with SIGSTOP to avoid 'find' asking the
# next interactive question before the loop iteration completes (which can
# cause out-of-order terminal output if the iteration writes any).
#
# Before doing that, write an extra line telling the main shell to resuming
# this process at the beginning of the next iteration, so this process
# terminates and 'find' asks the next interactive question.
#    Normally, writing an extra line causes an extra loop iteration. To
# avoid that, make the main shell explicitly read and eval another command
# before the next iteration. This must be the same read/eval as in the DO
# alias defined in var/loop.mm.

shellquote f=$1
putln "${_loop_V}=$f" \
	"command kill -s CONT $$ && IFS= read -r _loop_i <&8 && eval \" \${_loop_i}\"" \
	>&8 2>/dev/null || DIE
kill -s STOP $$
