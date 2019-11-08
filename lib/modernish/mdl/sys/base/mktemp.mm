#! /module/for/moderni/sh
\command unalias mktemp _Msh_mktemp_genSuffix 2>/dev/null

# modernish sys/base/mktemp
#
# A cross-platform shell implementation of 'mktemp' that aims to be just as
# safe as native mktemp(1) implementations, while avoiding the problem of
# having various mutually incompatible versions and adding several unique
# features of its own.
#
# Create one or more unique temporary files, directories or named pipes,
# atomically (i.e. avoiding race conditions) and with safe permissions.
# The path name(s) are stored in $REPLY and optionally written to stdout.
# Usage: mktemp [ -dFsQCt ] [ <template> ... ]
#	-d: Create a directory instead of a regular file.
#	-F: Create a FIFO (named pipe) instead of a regular file.
#	-s: Silent. Store output in $REPLY, don't write any output or message.
#	-Q: Shell-quote each unit of output. Separate by spaces, not newlines.
#	-C: Automated cleanup. Push a trap to remove the files on exit, SIGPIPE
#	    or SIGTERM. When given twice, clean up on SIGINT as well, otherwise
#	    notify the user of files left. When given three times, clean up on
#	    die() as well, otherwise notify.
#	-t: Prefix the given <template>s with $TMPDIR/ if TMPDIR is set, /tmp/
#	    otherwise. The <template>s may not contain any slashes.
# The template defaults to "/tmp/temp.". A suffix of ten random shellsafe
# characters is added to securely avoid conflicts with other files in the
# directory. Any trailing X characters are removed from the template before
# adding the suffix. If more than ten X characters are added, their number
# determines the suffix length.
#
# Option -C cannot be used while invoking 'mktemp' in a subshell, such as in
# a command substitution.. Reason: a typical command substitution like
#	tmpfile=$(mktemp -C)
# is incompatible with auto-cleanup, as the cleanup EXIT trap would be
# triggered not upon exiting the program but upon exiting the command
# substitution subshell that just ran 'mktemp', thereby immediately undoing
# the creation of the file. Instead, do something like:
#	mktemp -sC; tmpfile=$REPLY
#
# The -u option from other mktemp implementations is not supported. It's unsafe.
# The -q option is also not supported: this mktemp dies (kills the program) if
# an error occurs, so suppressing the error message would not make sense.
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

case $#,${2-} in
(2,-i)	_Msh_mktemp_insecure= ;;
( 1, )	unset -v _Msh_mktemp_insecure ;;
( * )	put "$1: invalid argument(s): $@$CCn"
	return 1 ;;
esac

use var/shellquote
use var/stack/trap	# for autocleanup, we need pushtrap

# Determine an internal function to create a file name suffix that is as securely random as possible.
# (Note the function is invoked from a command substitution subshell, so no need to save settings/variables.)

if is -L charspecial /dev/urandom && not isset _Msh_mktemp_insecure; then
	# We can get properly random data from the kernel. Good.
	_Msh_mktemp_genSuffix() {
		is -L charspecial /dev/urandom || exit 1 "mktemp: /dev/urandom not found"
		IFS=; set -f; export PATH=$DEFPATH LC_ALL=C; unset -f tr dd
		# Instead of letting 'tr' greedily suck data from /dev/urandom, be well behaved and use an initial 'dd'
		# to avoid taking more data from /dev/urandom than we need. This also keeps it working if SIGPIPE is
		# ignored (WRN_NOSIGPIPE compat). 16 times the suffix length should do to extract enough characters.
		exec dd bs=$((16 * _Msh_mT_tlen)) count=1 </dev/urandom 2>/dev/null \
			| exec tr -dc ${ASCIIALNUM}%+,.:=@_^!- \
			| exec dd bs=${_Msh_mT_tlen} count=1 2>/dev/null
	}
else
	# We cannot use /dev/urandom. Fall back to awk rand(), a plain pseudorandom generator. The lowest common denominator
	# 'awk' uses a 32 bit signed integer for srand() seeds, but then uses 64 bit floating point for the random generator
	# itself! But the inadequate 32 bit seed constraint would give us just 2^32 possible suffixes, regardless of length.
	# So add to the randomness: take our subshell's process ID and use it as the number of rand() iterations to discard.
	# On a typical system with 32768 (=2^15) PIDs, that should give us up to 2^47 possible suffixes. Quite a bit better.

	# ... init global random seed:
	_Msh_srand=$(unset -f awk; PATH=$DEFPATH exec awk \
		'BEGIN { srand(); printf("%d", rand() * 2^32 - 2^31); }') || return 1
	let "_Msh_srand ^= $$ ^ ${RANDOM:-0}"

	_Msh_mktemp_genSuffix() {
		IFS=; set -f; export PATH=$DEFPATH LC_ALL=C POSIXLY_CORRECT=y; unset -f awk
		insubshell -p
		exec awk -v seed2=$((REPLY ^ ${RANDOM:-0})) \
			 -v seed=${_Msh_srand} \
			 -v len=${_Msh_mT_tlen} \
			 -v chars=${ASCIIALNUM}%+,.:=@_^!- \
		'BEGIN {
			ORS="";
			srand(seed);
			for (i=0; i<seed2; i++)
				rand();
			# ...generate the suffix
			numchars=length(chars);
			for (i=0; i<len; i++)
				print substr(chars, rand()*numchars+1, 1);
			# ...attach re-seed value
			printf("/%d", rand() * 2^32 - 2^31);
		}'
	}
	unset -v _Msh_mktemp_insecure
fi

# Main function.

mktemp() {
	# ___begin option parser___
	# The command used to generate this parser was:
	# generateoptionparser -o -n 'dFsQt' -f 'mktemp' -v '_Msh_mTo_'
	# Then the counting C option, '--help', and the extended usage message were added manually.
	unset -v _Msh_mTo_d _Msh_mTo_F _Msh_mTo_s _Msh_mTo_Q _Msh_mTo_t
	_Msh_mTo_C=0
	while	case ${1-} in
		( -[!-]?* ) # split a set of combined options
			_Msh_mTo__o=${1#-}
			shift
			while not str empty "${_Msh_mTo__o}"; do
				set -- "-${_Msh_mTo__o#"${_Msh_mTo__o%?}"}" "$@"	#"
				_Msh_mTo__o=${_Msh_mTo__o%?}
			done
			unset -v _Msh_mTo__o
			continue ;;
		( -[dFsQt] )
			eval "_Msh_mTo_${1#-}=''" ;;
		( -C )  let "_Msh_mTo_C += 1" ;;
		( -- )	shift; break ;;
		( --help )
			putln "modernish $MSH_VERSION sys/base/mktemp" \
				"usage: mktemp [ -dFsQCt ] [ TEMPLATE ... ]" \
				"   -d: Create directories instead of regular files." \
				"   -F: Create FIFOs (named pipes) instead of a regular files." \
				"   -s: Silent. Only store filenames in REPLY." \
				"   -Q: Shell-quote each pathname. Separate by spaces." \
				"   -C: Push trap to remove created files on exit." \
				"   -t: Prefix one temporary files directory to the templates."
			return ;;
		( -* )	die "mktemp: invalid option: $1" \
				"${CCn}usage:${CCt}mktemp [ -dFsQCt ] [ TEMPLATE ... ]" \
				"${CCn}${CCt}mktemp --help" || return ;;
		( * )	break ;;
		esac
	do
		shift
	done
	# ^^^ end option parser ^^^
	if isset _Msh_mTo_d && isset _Msh_mTo_F; then
		die "mktemp: options -d and -F are incompatible"
	fi
	if let "_Msh_mTo_C > 0" && insubshell; then
		die "mktemp: -C: auto-cleanup can't be set from a subshell${CCn}" \
			"(e.g. can't do v=\$(mktemp -C); instead do mktemp -C; v=\$REPLY)" || return
	fi
	if isset _Msh_mTo_t; then
		if isset TMPDIR; then
			if not str begin "$TMPDIR" '/' || not is -L dir "$TMPDIR"; then
				die "mktemp: -t: value of TMPDIR must be an absolute path to a directory"
			fi
			_Msh_mTo_t=$TMPDIR
		else
			_Msh_mTo_t=/tmp
		fi
		for _Msh_mT_t do
			case ${_Msh_mT_t} in
			( */* )	die "mktemp: -t: template must not contain directory separators" ;;
			( *X | *. ) ;;
			( * )	_Msh_mT_t=${_Msh_mT_t}. ;;   # in -t mode, if there are no Xes and no separator dot, add the dot
			esac
			set -- "$@" "${_Msh_mTo_t}/${_Msh_mT_t}"
			shift
		done
	fi
	if let "${#}>1" && not isset _Msh_mTo_Q; then
		for _Msh_mT_t do
			case ${_Msh_mT_t} in
			( *["$WHITESPACE"]* )
				die "mktemp: multiple templates and at least 1 has whitespace: use -Q" ;;
			esac
		done
	fi
	if let "${#}<1"; then
		# default template
		set -- ${_Msh_mTo_t:-/tmp}/temp.
	fi

	REPLY=''
	for _Msh_mT_t do
		_Msh_mT_tlen=0
		while str end "${_Msh_mT_t}" X; do
			_Msh_mT_t=${_Msh_mT_t%X}
			let "_Msh_mT_tlen+=1"
		done
		let "_Msh_mT_tlen<10" && _Msh_mT_tlen=10

		# Make directory path absolute and physical (no symlink components).
		case ${_Msh_mT_t} in
		( */* )	_Msh_mT_td=$(command cd "${_Msh_mT_t%/*}" && command pwd -P; put x) ;;
		( * )	_Msh_mT_td=$(command pwd -P; put x) ;;
		esac || die "mktemp: internal error: failed to make absolute path"
		_Msh_mT_td=${_Msh_mT_td%${CCn}x} # in case PWD ends in linefeed, defeat linefeed stripping in cmd subst
		case ${_Msh_mT_td} in
		( / )	_Msh_mT_t=/${_Msh_mT_t##*/} ;;
		( * )	_Msh_mT_t=${_Msh_mT_td}/${_Msh_mT_t##*/} ;;
		esac

		# Keep trying until we succeed or a fatal error occurs.
		forever do
			_Msh_mT_tsuf=$(_Msh_mktemp_genSuffix) || die "mktemp: could not generate suffix"
			if str match "${_Msh_mT_tsuf}" '?*/?*'; then  # save awk random seed
				let "_Msh_srand = ${_Msh_mT_tsuf##*/} ^ ${RANDOM:-0}"
				_Msh_mT_tsuf=${_Msh_mT_tsuf%/*}
			fi
			str match "${_Msh_mT_tsuf}" '??????????*' || die "mktemp: failed to generate min. 10 char. suffix"
			# Big command substitution subshell with local settings below.
			REPLY=$REPLY$(
				IFS=''; set -f -u -C	# 'use safe' - no quoting needed below
				umask 0077		# safe perms on creation
				export PATH=$DEFPATH LC_ALL=C
				unset -f getconf	# QRK_EXECFNBI compat

				# Try to create the file, directory or FIFO, as close to atomically as we can.
				# If it fails, that can mean two things: the file already existed or there was a fatal error.
				# Only if and when it fails, check for fatal error conditions, and try again if there are none.
				# (Checking before trying would cause a race condition, risking an infinite loop here.)
				_Msh_file=${_Msh_mT_t}${_Msh_mT_tsuf}

				# ... attempt to create the item
				case ${_Msh_mTo_d+d}${_Msh_mTo_F+F} in
				( d )	command mkdir ${_Msh_file} 2>/dev/null ;;
				( F )	command mkfifo ${_Msh_file} 2>/dev/null ;;
				( '' )	# ... create regular file: in shell, this is not possible to do 100% securely in a
					# world-writable directory; 'set -C'/'set -o nocobber' is probably not atomic and in
					# any case does not block on pre-existing devices or FIFOs. Hopefully having at least
					# 10 chars of high-quality randomness from /dev/urandom helps a lot. Mitigate the risk
					# further by trying to catch any shenanigans after the fact.
					not is present ${_Msh_file} &&
					{ >${_Msh_file} is reg ${_Msh_file}; } 2>/dev/null &&
					can write ${_Msh_file} &&
					putln foo >|${_Msh_file} &&
					can read ${_Msh_file} &&
					read _Msh_f <${_Msh_file} &&
					str eq ${_Msh_f} foo >|${_Msh_file} ;;
				( * )	exit 1 'mktemp: internal error' ;;
				esac

				# check for fatal error conditions
				# (note: 'exit' will exit from this subshell only)
				_Msh_e=$?	# BUG_CASESTAT compat
				case ${_Msh_e} in
				( 0 )	# success!
					case ${_Msh_mTo_Q+y} in
					( y )	shellquote -f _Msh_file && put "${_Msh_file} " ;;
					( * )	putln ${_Msh_file} ;;
					esac ;;
				( ? | ?? | 1[01]? | 12[012345] )
					is -L dir ${_Msh_mT_t%/*} || exit 1 "mktemp: not a directory: ${_Msh_mT_t%/*}"
					can write ${_Msh_mT_t%/*} || exit 1 "mktemp: directory not writable: ${_Msh_mT_t%/*}"
					_Msh_max=$(exec getconf NAME_MAX ${_Msh_file%/*} 2>/dev/null); _Msh_name=${_Msh_file##*/}
					let "${#_Msh_name} > ${_Msh_max:-255}" && exit 1 "mktemp: filename too long: ${_Msh_name}"
					_Msh_max=$(exec getconf PATH_MAX ${_Msh_file%/*} 2>/dev/null)
					let "${#_Msh_file} > ${_Msh_max:-1024}" && exit 1 "mktemp: path too long: ${_Msh_file}"
					# non-fatal error: try again
					exit 147 ;;
				( 126 )	exit 1 "mktemp: system error: could not invoke command" ;;
				( 127 ) exit 1 "mktemp: system error: command not found" ;;
				( * )	if thisshellhas --sig=${_Msh_e}; then
						exit 1 "mktemp: system error: command killed by SIG$REPLY"
					fi
					exit 1 "mktemp: system error: command failed" ;;
				esac
			) # end of big command substitution subshell

			case $? in
			( 0 )	break ;;
			( 147 )	continue ;;
			( * )	die ;;
			esac
		done
	done

	isset _Msh_mTo_Q && REPLY=${REPLY% }	# remove extra trailing space
	isset _Msh_mTo_s && unset -v _Msh_mTo_s || putln "$REPLY"
	if let "_Msh_mTo_C > 0"; then
		unset -v _Msh_mT_qnames
		# Push cleanup trap: first generate safe arguments.
		if isset _Msh_mTo_Q; then
			# any number of shellquoted filenames
			_Msh_mT_qnames=$REPLY
		elif let "${#}==1"; then
			# single non-shellquoted filename
			shellquote _Msh_mT_qnames="$REPLY"
		else
			# multiple non-shellquoted newline-separated filenames, guaranteed no whitespace
			push IFS -f; IFS=$CCn; set -f
			for _Msh_mT_f in $REPLY; do
				shellquote _Msh_mT_f
				_Msh_mT_qnames=${_Msh_mT_qnames:+$_Msh_mT_qnames }${_Msh_mT_f}
			done
			pop IFS -f
		fi
		if thisshellhas QRK_EXECFNBI; then
			_Msh_mT_cmd='unset -f rm; '
		else
			_Msh_mT_cmd=''
		fi
		_Msh_mT_cmd="${_Msh_mT_cmd}PATH=\$DEFPATH exec rm -${_Msh_mTo_d+r}f ${_Msh_mT_qnames}"
		if isset -i; then
			# On interactive shells, EXIT is the only cleanup trap that makes sense.
			pushtrap "${_Msh_mT_cmd}" EXIT
		elif let "_Msh_mTo_C > 2"; then
			pushtrap "${_Msh_mT_cmd}" INT PIPE TERM EXIT DIE
		elif let "_Msh_mTo_C > 1"; then
			pushtrap "${_Msh_mT_cmd}" INT PIPE TERM EXIT
			shellquote _Msh_mT_qnames="mktemp: Leaving temp item(s): ${_Msh_mT_qnames}"
			pushtrap "putln \"\" ${_Msh_mT_qnames} 1>&2" DIE
		else
			pushtrap "${_Msh_mT_cmd}" PIPE TERM EXIT
			shellquote _Msh_mT_qnames="mktemp: Leaving temp item(s): ${_Msh_mT_qnames}"
			pushtrap "putln \"\" ${_Msh_mT_qnames} 1>&2" INT DIE
		fi
		unset -v _Msh_mT_qnames
	fi
	unset -v _Msh_mT_t _Msh_mT_td _Msh_mT_tlen _Msh_mT_tsuf _Msh_mT_cmd \
		_Msh_mTo_d _Msh_mTo_F _Msh_mTo_s _Msh_mTo_Q _Msh_mTo_t _Msh_mTo_C
}

if thisshellhas ROFUNC; then
	readonly -f mktemp _Msh_mktemp_genSuffix
fi
