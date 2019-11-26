#! /module/for/moderni/sh
\command unalias % _Msh_procsubst 2>/dev/null

# Here is a portable process substitution construct for all POSIX shells.
# We can't copy the ksh syntax, so we have to invent a new one. This module
# provides a '%' command for use within a command substitution. This '%'
# command takes a simple command as its arguments, executes it, and writes
# a file name from which to read its output (or, if the -o option is given,
# a file name to which to write the output that is to be its input).
#
# So the ksh command
#	diff -u <(ls) <(ls -a)
# can be translated to modernish as
#	diff -u <$(% ls) <$(% ls -a)
#	diff -u <`% ls` <`% ls -a`
#
# This only works with simple commands, including shell function calls but not
# aliases. Wrap compound commands, aliases, redirections, etc. in a function.
#
# The output variant >(foo) is implemented as $(% -o foo).
#
# So the ksh command
# 	tar cf >(bzip2 -c > file.tar.bz2) $directory_name
# can be translated to modernish as
#	tar cf $(% -o eval 'bzip2 -c > file.tar.bz2') $directory_name
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

command alias %='_Msh_procsubst'
_Msh_procsubst() {
	# 0. Parse options.
	unset -v _Msh_pSo_o
	while	case $1 in
		( -i )	unset -v _Msh_pSo_o ;;
		( -o )	_Msh_pSo_o= ;;
		( -- )	shift; break ;;
		( -* )	die "%: invalid option: $1" ;;
		( * )	break ;;
		esac
	do
		shift
	done

	# 1. Make a FIFO to read the command output.
	#    Be atomic and appropriately paranoid.
	_Msh_FIFO=${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/_Msh_FIFO_${$}_${RANDOM:-0} &&
	until (	umask 077			# private FIFOs
		PATH=$DEFPATH			# be sure to use the OS's stock 'mkfifo'
		unset -f mkfifo			# QRK_EXECFNBI compat
		exec mkfifo ${_Msh_FIFO} ) 2>/dev/null
	do
		_Msh_E=$?
		case ${_Msh_E} in
		( ? | ?? | 1[01]? | 12[012345] )
			is -L dir "${_Msh_FIFO%/*}" || die "%: system error: temp dir '${_Msh_FIFO%/*}' not found"
			can write "${_Msh_FIFO%/*}" || die "%: system error: temp dir '${_Msh_FIFO%/*}' not writable"
			# re-randomise, or add 1 to, the number at the end of the path, and try again
			_Msh_FIFO=${_Msh_FIFO%/*}/_Msh_FIFO_${$}_${RANDOM:-$(( ${_Msh_FIFO##*FIFO_${$}_} + 1 ))}
			continue ;;
		( 126 ) die "%: system error: could not invoke 'mkfifo'" ;;
		( 127 ) die "%: system error: 'mkfifo' not found" ;;
		( * )	use -q var/stack/trap && thisshellhas "--sig=${_Msh_E}" && die "%: 'mkfifo' killed by SIG$REPLY"
			die "%: system error: 'mkfifo' failed" ;;
		esac
	done 1>&1
	#    ^^^^ On AT&T ksh93 (NONFORKSUBSH), fork this cmd subst subshell to avoid hanging.

	# 2. Launch the bg job to run the command.
	(
		exec >&-	# close standard output, or the command substitution will block
		_Msh_pS_T='PATH=$DEFPATH; unset -f rm; exec rm -f "${_Msh_FIFO}"'  # QRK_EXECFNBI compat
		if use -q var/stack/trap; then
			pushtrap "${_Msh_pS_T}" DIE EXIT PIPE INT TERM
		else
			command trap "${_Msh_pS_T}" 0 PIPE INT TERM	# BUG_TRAPEXIT compat
			_Msh_POSIXtrapDIE=${_Msh_pS_T}			# cheat: set DIE trap w/o module
		fi
		if isset _Msh_pSo_o; then
			"$@" <"${_Msh_FIFO}"
		else
			"$@" >"${_Msh_FIFO}"
		fi
	) &

	# 3. Output the FIFO file name for the command substitution.
	putln "${_Msh_FIFO}"
}

if thisshellhas ROFUNC; then
	readonly -f _Msh_procsubst
fi
