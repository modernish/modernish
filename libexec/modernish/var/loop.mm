#! /module/for/moderni/sh
\command unalias _Msh_loop _Msh_loop_Solaris_workaround _Msh_loop_c _Msh_loop_setE _loop_checkvarname _loop_die 2>/dev/null

# modernish var/loop
#
# The 'var/loop' module provides an innovative, robust and extensible shell
# loop construct. Several powerful loop types are predefined -- see the
# var/loop/*.mm modules.
#
# Those also serve as good examples on how to make your own, as this loop
# construct is easy to extend: all you need to do is define a shell function
# with a name like '_loopgen_yourtype' that parses the loop arguments and
# outputs iterations one per line. Each iteration is a command to be eval-ed
# by the shell, so be sure to shellquote() everything!!! (Modernish
# shellquote() quotes strings in such a way that they are always one line.)
# 
# The basic form is a bit different from native shell loops. Note the caps:
#
#	LOOP <looptype> <arguments>; DO
#	 	<your commands here>
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

# ---------

# Everything starts with these three aliases. See explanation below.

alias LOOP='{ { { _Msh_loop'

alias DO='}; _Msh_loop_c && '\
'while _loop_E=0; IFS= read -r _loop_i <&8 && eval " ${_loop_i}"; do { '   # QRK_EVALNOOPT compat

if thisshellhas BUG_SCLOSEDFD; then
	alias DONE='} 8<&-; done; } 8</dev/null 8<&-; _Msh_loop_setE; }'
else
	alias DONE='} 8<&-; done; } 8<&-; _Msh_loop_setE; }'
	#			    ^^^^^ makes loop nesting possible
	#	      ^^^^^ protects the FIFO FD from being accessed or modified within the loop
fi

# To make loop nesting, 'break', 'continue 2', etc. work 100% as expected, it's
# not possible to keep the loop state in variabeles, which are global. Instead,
# we make creative use of the one local state that the POSIX shell keeps for
# arbitrary code blocks, even nested ones: file descriptors (FDs) 0-9, simply
# by appending a redirection to the block. So let's use 8 (it sort of looks
# like a loop). Connecting a background process to a block-local FD 8 allows us
# to keep the loop state in that background process. All the main shell needs
# to do is read commands from that FD and 'eval' them within a 'while' loop.
#
# The 'LOOP', 'DO' and 'DONE' aliases expand to a grammatically robust shell
# block, as it's wrapped in an outer { ... }. The 'LOOP' alias calls
# _Msh_loop(), which launches a loop iteration generator shell function in the
# a background, connecting it to the main shell process via FD 8. The 'DO' and
# 'DONE' aliases internally create a native shell 'while' loop that reads from
# that loop iteration generator, one line per iteration, 'eval'ing each line
# until either the command(s) eval'ed from that line produce a non-zero exit
# status status or there are no more lines to read.
#
# In the 'DONE' alias, the outer 8<&- makes FD 8 local to the block, initially
# closed. (Shells with BUG_SCLOSEDFD need to open it first, and then close it,
# to make that happen.) The loop init function opens this local FD with 'exec'.
# When the block is exited in any way, the shell automatically closes the local
# FD, which breaks the pipe to the background process and ends it, and restores
# the parent FD. So nested loops "just work".
#
# Loop generators are background shell functions defined in the _loopgen_TYPE
# namespace, where TYPE is the loop type used as the first argument to LOOP
# (_Msh_loop()). These must write >&8 properly shell-quoted commands for the
# main shell to 'eval' them safely, on one line per iteration. The modernish
# shellquote() function was designed for that purpose: it guarantees printable,
# one-line quoted strings.
#
# The loop's exit status is kept in the main shell's _loop_E variable. For
# correct loop nesting, the DO alias resets it to zero before every iteration.
# To interrupt a loop with a given exit status (say 2), loop generators should
# write a negated assignment, like 'putln "! _loop_E=2" >&8'. The exit status
# negation ('!') is needed to stop our internal 'while' loop without using
# 'break' (which is not BUG_EVALCOBR comptible as we 'eval' the command).
#
# BUGS: a cleverly constructed triplet of aliases can block most shenanigans,
# but not quite everything. We can't grammatically block redirections or pipes
# after the LOOP alias. A pipe there causes the loop initiator to be executed
# in a subshell, so its exec'ing of the FD is ineffective. The best we can
# do is die if it didn't work, using the '<&8 || die' check in the DO alias.
# Adding any redirections there does nothing except potentially create empty
# files, as _Msh_loop() execs its own FD and produces no output.

# ---------

# The function handling the loop init, called from the 'LOOP' alias.
# It sets up the background job and the FIFO to read from it.
#
# Note: all _loopgen_* functions are called as background jobs, with
# 'safe mode' settings active (split & glob disabled) by default.

_Msh_loop() {
	# 0. Determine if the given loop type is defined as a _loopgen_* function.
	case ${1-} in ( '' ) die "LOOP: type expected" || return ;; esac
	command unalias "_loopgen_$1" 2>/dev/null
	if ! PATH=/dev/null command -v "_loopgen_$1" >/dev/null; then
		isvarname "x$1" || die "LOOP: invalid type: $1" || return
		# Be nice: try to auto-load the module with the loop name
		is -L reg "$MSH_PREFIX/libexec/modernish/var/loop/$1.mm" || die "LOOP: no such loop: $1" || return
		use "var/loop/$1"
		PATH=/dev/null command -v "_loopgen_$1" >/dev/null \
			|| die "LOOP: internal error: var/loop/$1.mm has no _loopgen_$1 function" || return
	fi || return

	# Some shell/OS combinations have a race condition, so we sometimes have to try the whole procedure more than once.
	# On non-broken shell/OS combinations this should always succeed the first time. To know if it's broken, export the
	# _loop_DEBUG variable to the environment to get a warning each time a retry is done.

	until {
	# 1. Make a FIFO to read from the iterations generator.
	#    Be atomic and appropriately paranoid.
		_Msh_FIFO=${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/_loopFIFO_${$}_${RANDOM:-0} &&
		until (	umask 077			# private FIFOs
			PATH=$DEFPATH			# be sure to use the OS's stock 'mkfifo'
			unset -f mkfifo			# QRK_EXECFNBI compat
			exec mkfifo "${_Msh_FIFO}" ) 2>/dev/null
		do
			_Msh_E=$?			# BUG_CASESTAT compat
			case ${_Msh_E} in
			( ? | ?? | 1[01]? | 12[012345] )
				is -L dir "${_Msh_FIFO%/*}" || die "LOOP: system error: temp dir '${_Msh_FIFO%/*}' not found"
				can write "${_Msh_FIFO%/*}" || die "LOOP: system error: temp dir '${_Msh_FIFO%/*}' not writable"
				# re-randomise, or add 1 to, the number at the end of the path, and try again
				_Msh_FIFO=${_Msh_FIFO%/*}/_loopFIFO_${$}_${RANDOM:-$(( ${_Msh_FIFO##*FIFO_${$}_} + 1 ))}
				continue ;;
			( 126 ) die "LOOP: system error: could not invoke 'mkfifo'" ;;
			( 127 ) die "LOOP: system error: 'mkfifo' not found" ;;
			( * )	thisshellhas "--sig=${_Msh_E}" && die "LOOP: 'mkfifo' killed by SIG$REPLY"
				die "LOOP: system error: 'mkfifo' failed" ;;
			esac || return
		done &&
		# On Solaris, we need an ugly workaround. See further below.
		_Msh_loop_Solaris_workaround &&
	# 2. Start the iteration generator in the background, and do the setup for reading from it.
	#    No good reason at all for default split & glob there, so always give it the 'safe mode'.
	#    To check that it succeeded, use a verification line consisting of 'LOOPOK' + our main PID.
		case $- in
		( *m* )	# Avoid job control noise on terminal: start bg job from subshell.
			( ( IFS=''
			    set -fCu
			    putln LOOPOK$$ >&8
			    _loopgen_$1 "$@"
			  ) 2>&8 8>"${_Msh_FIFO}" &
			) 8>&2 2>/dev/null ;;
		( * )	# No job control.
			( IFS=''
			  set -fCu
			  putln LOOPOK$$ >&8
			  _loopgen_$1 "$@"
			) 8>"${_Msh_FIFO}" & ;;
		esac &&
		# Open the local file descriptor 8 so 'read' (in 'DO' alias) can use it to read from the FIFO.
		{ thisshellhas BUG_CMDEXEC && exec 8<"${_Msh_FIFO}" || command exec 8<"${_Msh_FIFO}"
		} 2>/dev/null &&
		IFS= read -r _Msh_E <&8 &&
		identic "${_Msh_E}" "LOOPOK$$"
	}; do
		# We should only get here on a broken OS/shell combination. There are too many, so try to cope. The 'exec' might
		# have failed with 'interrupted system call', killing the background process -- or, worse, the 'exec' might have
		# succeeded with the background process getting stuck as a race condition severed the FIFO connection. So, close
		# the failed FD and kill any stuck bg job. Die on shenanigans, otherwise unlink the failed FIFO and try again.
		exec 8<&-
		case $- in
		( *m* )	# Job control: the bg job was started from a subshell, so we don't know a PID to kill.
			putln "LOOP $1: WARNING: race condition caught. A stuck background process may be left." >&2 ;;
		( * )	PATH=$DEFPATH command kill -s PIPE "$!" 2>/dev/null
			PATH=$DEFPATH command kill -s TERM "$!" 2>/dev/null
			PATH=$DEFPATH command kill -s KILL "$!" 2>/dev/null ;;
		esac
		is fifo "${_Msh_FIFO}" || die "LOOP: internal error: the FIFO disappeared" || return
		can read "${_Msh_FIFO}" || die "LOOP: internal error: no read permission on the FIFO" || return
		PATH=$DEFPATH command rm "${_Msh_FIFO}" || die "LOOP: internal error: can't remove failed FIFO" || return
		if isset _loop_DEBUG; then putln "[DEBUG] LOOP $1: RACE CONDITION CAUGHT! Cleanup done. Retrying." >&2; fi
	done

	# 3. Unlink the FIFO early.
	#    As long as the input and output redirections stay open, it will keep working!
	#    Cleanup can now safely be left to the shell and the kernel.
	case $- in
	( *m* )	# Slow, but avoids job control noise on terminal
		PATH=$DEFPATH command rm -f "${_Msh_FIFO}" ;;
	( * )	# No job control: don't wait for rm, send it to background
		(PATH=$DEFPATH
		unset -f rm	# QRK_EXECFNBI compat
		exec rm -f "${_Msh_FIFO}") & ;;
	esac
	unset -v _Msh_FIFO _Msh_E
} >&-
# ^^^ Close standard output for this entire function, including the loop generator background process it spawns.

# See if we need a workaround.

case $(PATH=$DEFPATH; unset -f uname; exec uname -s) in   # QRK_EXECFNBI compat
( SunOS )
	# Solaris (at least up to 11.4) is strangely broken: FIFOs aren't ready for use immediately after creation.
	# We have to wait at least half a second before our 'exec' will work, otherwise the shell will simply hang
	# on the next 'read'. This applies to ksh93 (/bin/sh) and bash, but *not* to yash, zsh and mksh, which cope
	# just fine. TODO: This is obviously a very ugly hack and we need a real workaround! Anyone?
	case ${KSH_VERSION-}${BASH_VERSION+bash} in
	( Version* | bash )
		_Msh_loop_Solaris_workaround() { PATH=$DEFPATH command sleep 1; } ;;
	( * )	_Msh_loop_Solaris_workaround() { : ; } ;;
	esac ;;
( * )	_Msh_loop_Solaris_workaround() { : ; } ;;
esac

# Internal function for DO alias to check the file descriptor.
#
# This is separated into a shell function so that, on zsh, combining modernish with a
# native script using "sticky emulation" works as expected (sticky emulation does not
# apply to aliases and the 'command' builtin does a different thing in zsh native mode).

_Msh_loop_c() {
	command : <&8 || die "LOOP: lost connection to iteration generator"
}

# Internal function for DONE alias to set $? to the loop's saved exit status. Do a little cleanup while
# we're at it.

_Msh_loop_setE() {
	# Use 'eval' for early expansion so we can unset the variable and still use it for exit status.
	eval "unset -v _loop_i _loop_E; return ${_loop_E}";
}

# ---------

# Helper functions for use in loop generator background processes

# _loop_die: Outputs a 'die' command for the main shell to eval, then exits. Simple 'die' from background
# jobs works, but is less graceful as the main shell is SIGKILLed. Also, if any DIE traps were set/pushed
# within the loop, the background job would lack them; this way makes sure they are executed. Finally, unlike
# die(), _loop_die() will achieve nothing if the command failed with an I/O error due to the user having
# broken out of the loop, which is exactly how it should be. Usage: _loop_die "looptype: error message"

_loop_die() {
	shellquoteparams
	put "die LOOP $@$CCn" >&8
	exit 128
}

# _loop_checkvarname: Checks that a variable name is valid and doesn't belong to the modernish internal
# namespace (_Msh_*) or the loop internal namespace (_loop_*). We want to die on any attempt to use an
# internal namespace, as loop generators sometimes need to evaluate expressions, such as arithmetic
# assignments, in their own background process. The second argument will be passed on to the error message.

_loop_checkvarname() {
	case $# in
	( [!2] | ??* )
		die "_loop_checkvarname: invalid arguments${CCn}Usage: _loop_checkvar LOOPTYPE POSSIBLE_VARNAME"
	esac
	isvarname "$2" || _loop_die "$1: invalid variable name: $2"
	case +$2 in 
	( *[!_$ASCIIALNUM]_Msh_* | *[!_$ASCIIALNUM]_loop_* )
		_loop_die "$1: cannot use internal namespace" ;;
	esac
}

# ---------

if thisshellhas ROFUNC; then
	readonly -f _Msh_loop _Msh_loop_Solaris_workaround _Msh_loop_c _Msh_loop_setE _loop_checkvarname _loop_die
fi
