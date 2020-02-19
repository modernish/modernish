#! /helper/script/for/moderni/sh
IFS=''; set -fCu  # safe mode

# This is a helper script used by 'LOOP find' to execute commands specified
# for -exec or -ok in the main shell instead of as an external command.
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

# Use modernish shell-quoting (via find.awk) to write the command to the
# calling shell for execution, including an extra command to send SIGUSR1 to
# this process if there is a nonzero exit status. Then stop this process
# until told to continue by the main shell.
#
# At that point, the main shell will also have sent SIGUSR1 to this script if
# the command exited unsuccessfully. This is used to pass the zero/nonzero exit
# status of the main command on to 'find' upon exit. This means the command
# executed in the main shell is capable of physically influencing directory
# traversal mid-run (if the 'find' expression is written to do that).
#
# Tell the awk script to write an extra line telling the main shell to resume
# this process at the beginning of the next iteration, so this process
# terminates and 'find' continues processing.

mainstatus=0  # exit status for command executed in calling shell
trap 'mainstatus=1' USR1

awk -v _loop_exec=1 -v _loop_SIGCONT=$$ -f ${_loop_AUX}/find.awk -- "$@" >&8 &
kill -s STOP $$	# freeze until SIGCONT
# SIGCONT received, maybe preceded by SIGUSR1, so mainstatus may be 0 or 1
wait $!		# obtain awk's exit status
e=$?
case $e in
( 0 )	exit $mainstatus ;;  # pass status on to 'find', allowing command to influence directory traversal
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
