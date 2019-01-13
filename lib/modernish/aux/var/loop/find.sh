#! /helper/script/for/moderni/sh
#! use safe

# This is a helper script called by the '-exec' primary of 'find' in the
# var/loop/find module. It turns its arguments into assignments for the main
# shell to eval.
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

# Check that either the variable or the xargs option was exported to here, but not both.

case ${MSH_VERSION+O}${_loop_V+K}${_loop_xargs+K} in
( OK )	;;
( * )	case ${MSH_VERSION+m} in
	( '' )	echo "find.sh cannot be called directly." >&2
		exit 128 ;;
	esac
	putln "die 'LOOP find: internal error'" >&8 || kill -s KILL $PPID $$
	DIE ;;
esac

# Use modernish shellquote() to guarantee one shellquoted loop iteration
# command per line, so the main shell can safely 'read -r' and 'eval' any
# possible file names from the FIFO.

if isset _loop_xargs; then
	if str empty ${_loop_xargs}; then
		# Generate a 'set --' command to fill the PPs.
		put "set --" || DIE
		for f do
			shellquote f
			put " $f" || DIE
		done
		put "$CCn" || DIE
	else
		# Generate a ksh93-style array assignment.
		put "${_loop_xargs}=(" || DIE
		for f do
			shellquote f
			put " $f" || DIE
		done
		put " )$CCn" || DIE
	fi
else
	# Generate one assignment iteration per file.
	for f do
		shellquote f
		put "${_loop_V}=$f$CCn" || DIE
	done
fi >&8 2>/dev/null
