#! /module/for/moderni/sh
\command unalias shuf _Msh_shuf_do_e _Msh_shuf_do_i 2>/dev/null

# modernish sys/base/shuf
#
# Shuffle lines of text. A reimplementation of a commonly used GNU utility.
#
# Usage: shuf [ -n MAX ] [ -r RFILE ] FILE
#	 shuf [ -n MAX ] [ -r RFILE ] -i LOW-HIGH
#	 shuf [ -n MAX ] [ -r RFILE ] -e ARGUMENT ...
#
# By default, shuf reads lines of text from standard input, or from FILE if not
# equal to '-'. It writes the input lines to standard output in random order.
#
#	-i: Use sequence of non-negative integers LOW through HIGH as input.
#	-e: Instead of reading input, use the ARGUMENTs as lines of input.
#	-n: Output a maximum of MAX lines.
#	-r: Read random bytes from RFILE. Defaults to /dev/urandom.
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

if thisshellhas WRN_NOSIGPIPE; then
	# If SIGPIPE is ignored, 'od' cannot be interrupted from writing
	# infinite random numbers from /dev/urandom. For some reason, no
	# current 'od' implementation checks for write errors.
	putln "sys/base/shuf: SIGPIPE is being ignored. This would cause 'shuf' to hang."
	return 1
fi

use sys/cmd/procsubst
\command unalias awk sed sort 2>/dev/null

shuf() (
	# Safe mode. Quoting expansions is optional below.
	IFS=''
	set -fCu

	# Ensure standard utilities and locale.
	export PATH=$DEFPATH LC_ALL=C
	unset -f awk sed sort

	# ___ begin option parser ___
	unset -v _Msh_shuf_e _Msh_shuf_i _Msh_shuf_n _Msh_shuf_r
	while	case ${1-} in
		( -[!-]?* ) # split a set of combined options
			_Msh_shuf__o=$1
			shift
			while _Msh_shuf__o=${_Msh_shuf__o#?} && not str empty "${_Msh_shuf__o}"; do
				_Msh_shuf__a=-${_Msh_shuf__o%"${_Msh_shuf__o#?}"} # "
				push _Msh_shuf__a
				case ${_Msh_shuf__o} in
				( [inr]* ) # split optarg
					_Msh_shuf__a=${_Msh_shuf__o#?}
					not str empty "${_Msh_shuf__a}" && push _Msh_shuf__a && break ;;
				esac
			done
			while pop _Msh_shuf__a; do
				set -- "${_Msh_shuf__a}" "$@"
			done
			unset -v _Msh_shuf__o _Msh_shuf__a
			continue ;;
		( -[e] )
			eval "_Msh_shuf_${1#-}=''" ;;
		( -[inr] )
			let "$# > 1" || die "shuf: $1: option requires argument"
			eval "_Msh_shuf_${1#-}=\$2"
			shift ;;
		( -- )	shift; break ;;
		( -* )	die "shuf: invalid option: $1" ;;
		( * )	break ;;
		esac
	do
		shift
	done
	# ^^^ end option parser ^^^

	if isset _Msh_shuf_e; then
		if isset _Msh_shuf_i; then
			die "shuf: -e and -i are incompatible"
		fi
		let $# || exit 0
		command exec < $(% _Msh_shuf_do_e "$@") || die "shuf -e: internal error: failed to redirect"
	elif let "$# == 1" && not str eq $1 '-'; then
		command exec < $1 || die "shuf: not accessible: $1"
	elif let $#; then
		die "shuf: excess arguments"
	fi

	if isset _Msh_shuf_i; then
		str match ${_Msh_shuf_i} ?*-?* \
		&& _Msh_n=${_Msh_shuf_i%%-*} && str isint ${_Msh_n} \
		&& _Msh_m=${_Msh_shuf_i#*-}  && str isint ${_Msh_m} \
		&& let "_Msh_n >= 0 && _Msh_m >= _Msh_n" \
		|| die "shuf -i: invalid range: ${_Msh_shuf_i}"
		command exec < $(% _Msh_shuf_do_i ${_Msh_n} ${_Msh_m}) || die "shuf -i: internal error: failed to redirect"
	fi

	if isset _Msh_shuf_n; then
		str isint ${_Msh_shuf_n} && let "_Msh_shuf_n >= 0" || die "shuf: invalid number: ${_Msh_shuf_n}"
		let "(_Msh_shuf_n = _Msh_shuf_n) == 0" && exit
	fi

	if isset _Msh_shuf_r; then
		export _Msh_shuf_r
	fi

	# Do the job.
	(
		# Prepend random numbers to each line. Getting 'od' to produce 32-bit unsigned integers
		# (-t uI) allows for over 4.2 billion possible line numbers, which ought to be enough.
		awk 'BEGIN {
			for (;;) {
				"exec od -v -A n -t uI \"${_Msh_shuf_r:-/dev/urandom}\"" | getline
				if (! NF) exit 1;			# od failed: die
				for (i = 1; i <= NF; i++) {
					if ($i + 0 != $i) exit 1;	# not a number: die
					if (! getline L) exit 0;
					print $i ":" L;
				}
			}
		}' || let "$? == SIGPIPESTATUS" || die "shuf: failed to obtain randomness"
	) | (
		# Sort lines by their added random numbers.
		sort -n || let "$? == SIGPIPESTATUS" || die "shuf: internal error: 'sort' failed"
	) | (
		# Remove the random numbers; if -e is given, unescape newlines; if -n is given, quit when reached.
		exec sed "
			s/^[0-9]*://
			${_Msh_shuf_e+s/@n/\\$CCn/g; s/@@/@/g}
			${_Msh_shuf_n:+$_Msh_shuf_n q}
		"
	) || let "$? == SIGPIPESTATUS" || die "shuf: internal error: 'sed' failed"
)

_Msh_shuf_do_e() {
	# Arguments given with -e may contain newlines, but those additional
	# lines must not be shuffled. Escape any newlines in the arguments.
	awk 'BEGIN {
		for (i = 1; i < ARGC; i++) {
			s = ARGV[i];
			gsub(/@/, "@@", s);
			gsub(/\n/, "@n", s);
			print s;
		}
	}' "$@" || let "$? == SIGPIPESTATUS" || die "shuf -e: internal error: 'awk' failed"
}

_Msh_shuf_do_i() {
	awk -v n=$(($1)) -v m=$(($2)) 'BEGIN {
		for (i = n; i <= m; i++) print i;
	}' || let "$? == SIGPIPESTATUS" || die "shuf -i: internal error: 'awk' failed"
}

if thisshellhas ROFUNC; then
	readonly -f shuf _Msh_shuf_do_e _Msh_shuf_do_i
fi
