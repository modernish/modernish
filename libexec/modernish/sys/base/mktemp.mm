#! /module/for/moderni/sh

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
# Any trailing 'X' characters in the template are replaced by more-or-less
# random ASCII characters. The template defaults to: /tmp/temp.XXXXXXXX
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

mktemp() {
	# ___begin option parser___
	unset -v _Msh_mTo_d _Msh_mTo_F _Msh_mTo_s _Msh_mTo_Q _Msh_mTo_t
	_Msh_mTo_C=0
	forever do
		case ${1-} in
		( -[!-]?* ) # split a set of combined options
			_Msh_mTo__o=${1#-}
			shift
			while not empty "${_Msh_mTo__o}"; do
				set -- "-${_Msh_mTo__o#"${_Msh_mTo__o%?}"}" "$@"	#"
				_Msh_mTo__o=${_Msh_mTo__o%?}
			done
			unset -v _Msh_mTo__o
			continue ;;
		( -[dFsQt] )
			eval "_Msh_mTo_${1#-}=''" ;;
		( -C )  let "_Msh_mTo_C += 1" ;;
		( -- )	shift; break ;;
		( -* )	die "mktemp: invalid option: $1" || return ;;
		( * )	break ;;
		esac
		shift
	done
	# ^^^ end option parser ^^^
	if isset _Msh_mTo_d && isset _Msh_mTo_F; then
		die "mktemp: options -d and -F are incompatible" || return
	fi
	if let "_Msh_mTo_C > 0" && insubshell; then
		die "mktemp: -C: auto-cleanup can't be set from a subshell${CCn}" \
			"(e.g. can't do v=\$(mktemp -C); instead do mktemp -C; v=\$REPLY)" || return
	fi
	if isset _Msh_mTo_t; then
		if isset TMPDIR; then
			if not startswith "$TMPDIR" '/' || not is -L dir "$TMPDIR"; then
				die "mktemp: -t: value of TMPDIR must be an absolute path to a directory" || return
			fi
			_Msh_mTo_t=$TMPDIR
		else
			_Msh_mTo_t=/tmp
		fi
		for _Msh_mT_t do
			case ${_Msh_mT_t} in
			( */* )	die "mktemp: -t: template must not contain directory separators" || return ;;
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
				die "mktemp: multiple templates and at least 1 has whitespace: use -Q" || return ;;
			esac
		done
	fi
	if let "${#}<1"; then
		# default template
		set -- ${_Msh_mTo_t:-/tmp}/temp.
	fi

	# Big command substitution subshell below. Beware of BUG_CSCMTQUOT: avoid unbalanced quotes in comments below

	REPLY=$(IFS=''; set -f -u -C	# 'use safe' - no quoting needed below
		umask 0077		# safe perms on creation
		export PATH=$DEFPATH
		# for QRK_LOCALUNS/QRK_LOCALUNS2 compat, keep using _Msh_ namespace prefix in subshell
		unset -v i _Msh_tmpl _Msh_tlen _Msh_tsuf _Msh_file
		# for QRK_EXECFNBI compat
		unset -f tr dd

		for _Msh_tmpl do
			_Msh_tlen=0
			while endswith ${_Msh_tmpl} X; do
				_Msh_tmpl=${_Msh_tmpl%X}
				let "_Msh_tlen+=1"
			done
			let "_Msh_tlen<10" && _Msh_tlen=10

			# Make directory path absolute and physical (no symlink components).
			case ${_Msh_tmpl} in
			( */* )	_Msh_tmpld=$(command cd ${_Msh_tmpl%/*} && command pwd -P; put x) ;;
			( * )	_Msh_tmpld=$(command pwd -P; put x) ;;
			esac || exit
			_Msh_tmpld=${_Msh_tmpld%${CCn}x} # in case PWD ends in linefeed, defeat linefeed stripping in cmd subst
			case ${_Msh_tmpld} in
			( / )	_Msh_tmpl=/${_Msh_tmpl##*/} ;;
			( * )	_Msh_tmpl=${_Msh_tmpld}/${_Msh_tmpl##*/} ;;
			esac

			# Try to create the file, directory or FIFO, as close to atomically as we can.
			# If it fails, that can mean two things: the file already existed or there was a fatal error.
			# Only if and when it fails, check for fatal error conditions, and try again if there are none.
			# (Checking before trying would cause a race condition, risking an infinite loop here.)
			until	# ... generate suffix
				is -L charspecial /dev/urandom || exit 1 "mktemp: /dev/urandom not found"
				_Msh_tsuf=$(LC_ALL=C exec tr -dc ${ASCIIALNUM}%+,.:=@_^!- </dev/urandom \
					| exec dd bs=${_Msh_tlen} count=1 2>/dev/null)
				empty ${_Msh_tsuf} && exit 1 "mktemp: failed to generate suffix"
				_Msh_file=${_Msh_tmpl}${_Msh_tsuf}
				# ... attempt to create the item
				case ${_Msh_mTo_d+d}${_Msh_mTo_F+F} in
				( d )	command mkdir ${_Msh_file} 2>/dev/null ;;
				( F )	command mkfifo ${_Msh_file} 2>/dev/null ;;
				( '' )	# ... create regular file: in shell, this is not possible to do 100% securely in a
					# world-writable directory; 'set -c'/'set -o nocobber' is probably not atomic and in
					# any case does not block on pre-existing devices or FIFOs. Hopefully having at least
					# 10 chars of high-quality randomness from /dev/urandom helps a lot. Mitigate the risk
					# further by trying to catch any shenanigans after the fact.
					not is present ${_Msh_file} &&
					>${_Msh_file} is reg ${_Msh_file} &&
					can write ${_Msh_file} &&
					putln foo >|${_Msh_file} &&
					can read ${_Msh_file} &&
					read _Msh_f <${_Msh_file} &&
					identic ${_Msh_f} foo >|${_Msh_file} ;;
				( * )	exit 1 'mktemp: internal error' ;;
				esac
			do
				# check for fatal error conditions
				# (note: 'exit' will exit from this subshell only)
				_Msh_e=$?	# BUG_CASESTAT compat
				case ${_Msh_e} in
				( ? | ?? | 1[01]? | 12[012345] )
					;;  # ok
				( 126 )	exit 1 "mktemp: system error: could not invoke command" ;;
				( 127 ) exit 1 "mktemp: system error: command not found" ;;
				( * )	if thisshellhas --sig=${_Msh_e}; then
						exit 1 "mktemp: system error: command killed by SIG$REPLY"
					fi
					exit 1 "mktemp: system error: command failed" ;;
				esac
				is -L dir ${_Msh_tmpl%/*} || exit 1 "mktemp: not a directory: ${_Msh_tmpl%/*}"
				can write ${_Msh_tmpl%/*} || exit 1 "mktemp: directory not writable: ${_Msh_tmpl%/*}"
				# none found: try again
			done
			case ${_Msh_mTo_Q+y} in
			( y )	shellquote -f _Msh_file
				put "${_Msh_file} " ;;
			( * )	putln ${_Msh_file} ;;
			esac
		done
	) || die || return

	# ^^^ end of big command substitution subshell; resuming normal operation ^^^

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
			_Msh_mT_qnames=$REPLY
			shellquote _Msh_mT_qnames
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
			_Msh_mT_qnames="mktemp: Leaving temp item(s): ${_Msh_mT_qnames}"
			shellquote _Msh_mT_qnames
			pushtrap "putln \"\" ${_Msh_mT_qnames} 1>&2" DIE
		else
			pushtrap "${_Msh_mT_cmd}" PIPE TERM EXIT
			_Msh_mT_qnames="mktemp: Leaving temp item(s): ${_Msh_mT_qnames}"
			shellquote _Msh_mT_qnames
			pushtrap "putln \"\" ${_Msh_mT_qnames} 1>&2" INT DIE
		fi
		unset -v _Msh_mT_qnames
	fi
	unset -v _Msh_mT_t _Msh_mTo_d _Msh_mTo_F _Msh_mTo_s _Msh_mTo_Q _Msh_mTo_t _Msh_mTo_C Msh_mT_cmd
}

if thisshellhas ROFUNC; then
	readonly -f mktemp
fi
