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
# Usage: mktemp [ -dFsQC ] [ <template> ... ]
#	-d: Create a directory instead of a regular file.
#	-F: Create a FIFO (named pipe) instead of a regular file.
#	-s: Silent. Store output in $REPLY, don't write any output or message.
#	-Q: Shell-quote each unit of output. Separate by spaces, not newlines.
#	-C: Automated cleanup. Push a trap to remove the files on exit, SIGPIPE
#	    or SIGTERM. When given twice, clean up on SIGINT as well, otherwise
#	    notify the user of files left. When given three times, clean up on
#	    die() as well, otherwise notify.
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
# Copyright (c) 2016 Martijn Dekker <martijn@inlv.org>, Groningen, Netherlands
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

if	_Msh_test=$(PATH=$DEFPATH command mktemp /tmp/_Msh_mktemp_test.XXXXXXXX 2>/dev/null) &&
	startswith "${_Msh_test}" '/tmp/_Msh_mktemp_test.' &&
	is reg "${_Msh_test}" &&
	PATH=$DEFPATH command rm "${_Msh_test}"
then
# We have a functioning mktemp(1) in the default operating system path. Use it
# to create regular files only, one at a time, in a way compatible with all the
# different implementations of it.
mktemp() {
	# ___begin option parser___
	unset -v _Msh_mTo_d _Msh_mTo_F _Msh_mTo_s _Msh_mTo_Q
	_Msh_mTo_C=0
	forever do
		case ${1-} in
		( -??* ) # split a set of combined options
			_Msh_mTo__o=${1#-}
			shift
			while not empty "${_Msh_mTo__o}"; do
				case $# in
				( 0 ) set -- "-${_Msh_mTo__o#"${_Msh_mTo__o%?}"}" ;;	# BUG_UPP compat
				( * ) set -- "-${_Msh_mTo__o#"${_Msh_mTo__o%?}"}" "$@" ;;
				esac
				_Msh_mTo__o=${_Msh_mTo__o%?}
			done
			unset -v _Msh_mTo__o
			continue ;;
		( -[dFsQ] )
			eval "_Msh_mTo_${1#-}=''" ;;
		( -C )	let "_Msh_mTo_C += 1" ;;
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
	if let "${#}>1" && not isset _Msh_mTo_Q; then
		for _Msh_mT_t do
			case ${_Msh_mT_t} in
			( *["$WHITESPACE"]* )
				die "mktemp: multiple templates and at least 1 has whitespace: use -Q" || return ;;
			esac
		done
		unset -v _Msh_mT_t
	fi
	let "${#}<1" && set -- /tmp/temp.

	# Big command substitution subshell below. Beware of BUG_CSCMTQUOT: avoid unbalanced quotes in comments below

	REPLY=$(IFS=''; set -f -u	# 'use safe' - no quoting needed below
		umask 0077		# safe perms on creation
		unset -v i tmpl tlen tsuf cmd tmpfile mypid

		for tmpl do
			tlen=0
			while endswith $tmpl X; do
				tmpl=${tmpl%X}
				let "tlen+=1"
			done
			let "tlen>=8" || tlen=8

			case ${_Msh_mTo_d+d}${_Msh_mTo_F+F} in
			( d | F )
				if not isset mypid; then
					getmyshellpid; mypid=$REPLY
				fi
				i=$(( ${RANDOM:-$$} * mypid ))
				tsuf=$(PATH=$DEFPATH command printf %0${tlen}X $i) \
				|| exit 1 "mktemp: system 'printf' command failed"
				until	tmpfile=$tmpl$tsuf
					case ${_Msh_mTo_d+d}${_Msh_mTo_F+F} in
					( d )	PATH=$DEFPATH command mkdir $tmpfile 2>/dev/null ;;
					( F )	PATH=$DEFPATH command mkfifo $tmpfile 2>/dev/null ;;
					( * )	exit 1 'mktemp: internal error' ;;
					esac
				do
					# check for fatal error conditions
					# (note: 'exit' will exit from this subshell only)
					case $? in
					( 126 )	exit 1 "mktemp: system error: could not invoke command" ;;
					( 127 ) exit 1 "mktemp: system error: command not found" ;;
					esac
					case $tmpl in
					( */* )	is -L dir ${tmpl%/*} || exit 1 "mktemp: not a directory: ${tmpl%/*}"
						can write ${tmpl%/*} || exit 1 "mktemp: directory not writable: ${tmpl%/*}" ;;
					( * )	can write . || exit 1 "mktemp: directory not writable: $PWD" ;;
					esac
					# none found: try again
					case ${RANDOM+s} in
					( s )	i=$(( $RANDOM * $RANDOM )) ;;
					( * )	let "i-=1" ;;
					esac
					tsuf=$(PATH=$DEFPATH command printf %0${tlen}X $i) \
					|| exit 1 "mktemp: system 'printf' command failed"
				done ;;
			( '' )	while let '(tlen-=1)>=0'; do
					tmpl=${tmpl}X
				done
				tmpfile=$(PATH=$DEFPATH command mktemp $tmpl) || exit 1 "mktemp: system 'mktemp' command failed"
				;;
			( * )	exit 1 'mktemp: internal error' ;;
			esac
			case ${_Msh_mTo_Q+y} in
			( y )	shellquote -f tmpfile
				put "$tmpfile " ;;
			( * )	putln $tmpfile ;;
			esac
		done
	) || die || return
	isset _Msh_mTo_Q && REPLY=${REPLY% }	# remove extra trailing space
	isset _Msh_mTo_s && unset -v _Msh_mTo_s || putln "$REPLY"
	if let "_Msh_mTo_C > 0"; then
		unset -v _Msh_mT_qnames
		# Push cleanup trap: first generate safe arguments for 'rm -rf'.
		if isset _Msh_mTo_Q; then
			# any number of shellquoted filenames
			_Msh_mT_qnames=$REPLY
		elif let "${#}==1"; then
			# single non-shellquoted filename
			_Msh_mT_qnames=$REPLY
			shellquote _Msh_mT_qnames
		else
			# multiple non-shellquoted newline-separated filenames, guaranteed no whitespace
			while IFS='' read -r _Msh_mT_f; do
				shellquote _Msh_mT_f
				_Msh_mT_qnames=${_Msh_mT_qnames:+$_Msh_mT_qnames }${_Msh_mT_f}
			done <<-EOF
			$REPLY
			EOF
		fi
		if isset -i; then
			# On interactive shells, EXIT is the only cleanup trap that makes sense.
			pushtrap "PATH=\$DEFPATH command rm -rf ${_Msh_mT_qnames}" EXIT
		elif let "_Msh_mTo_C > 2"; then
			pushtrap "PATH=\$DEFPATH command rm -rf ${_Msh_mT_qnames}" INT PIPE TERM EXIT DIE
		elif let "_Msh_mTo_C > 1"; then
			pushtrap "PATH=\$DEFPATH command rm -rf ${_Msh_mT_qnames}" INT PIPE TERM EXIT
			_Msh_mT_qnames="mktemp: Leaving temp item(s): ${_Msh_mT_qnames}"
			shellquote _Msh_mT_qnames
			pushtrap "putln \"\" ${_Msh_mT_qnames} 1>&2" DIE
		else
			pushtrap "PATH=\$DEFPATH command rm -rf ${_Msh_mT_qnames}" PIPE TERM EXIT
			_Msh_mT_qnames="mktemp: Leaving temp item(s): ${_Msh_mT_qnames}"
			shellquote _Msh_mT_qnames
			pushtrap "putln \"\" ${_Msh_mT_qnames} 1>&2" INT DIE
		fi
		unset -v _Msh_mT_qnames
	fi
	unset -v _Msh_mTo_d _Msh_mTo_Q _Msh_mTo_F _Msh_mTo_C || :	# BUG_UNSETFAIL compat
}

else

# Canonical version.
mktemp() {
	# ___begin option parser___
	unset -v _Msh_mTo_d _Msh_mTo_F _Msh_mTo_s _Msh_mTo_Q
	_Msh_mTo_C=0
	forever do
		case ${1-} in
		( -??* ) # split a set of combined options
			_Msh_mTo__o=${1#-}
			shift
			while not empty "${_Msh_mTo__o}"; do
				case $# in
				( 0 ) set -- "-${_Msh_mTo__o#"${_Msh_mTo__o%?}"}" ;;	# BUG_UPP compat
				( * ) set -- "-${_Msh_mTo__o#"${_Msh_mTo__o%?}"}" "$@" ;;
				esac
				_Msh_mTo__o=${_Msh_mTo__o%?}
			done
			unset -v _Msh_mTo__o
			continue ;;
		( -[dFsQ] )
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
	if let "${#}>1" && not isset _Msh_mTo_Q; then
		for _Msh_mT_t do
			case ${_Msh_mT_t} in
			( *["$WHITESPACE"]* )
				die "mktemp: multiple templates and at least 1 has whitespace: use -Q" || return ;;
			esac
		done
		unset -v _Msh_mT_t
	fi
	let "${#}<1" && set -- /tmp/temp.

	# Big command substitution subshell below. Beware of BUG_CSCMTQUOT: avoid unbalanced quotes in comments below

	REPLY=$(IFS=''; set -f -u	# 'use safe' - no quoting needed below
		umask 0077		# safe perms on creation
		unset -v i tmpl tlen tsuf cmd tmpfile tmpdir mypid
		getmyshellpid; mypid=$REPLY

		for tmpl do
			tlen=0
			while endswith $tmpl X; do
				tmpl=${tmpl%X}
				let "tlen+=1"
			done
			let "tlen>=8" || tlen=8

			case ${_Msh_mTo_d+d}${_Msh_mTo_F+F} in
			( '' )	# We\'re creating a file. To be parallel-proof, do this inside a dedicated
				# subdirectory; then hard-link the file back out into the parent directory.
				# (Use the same template for the directory to make sure it\'s on the same file
				# system, so we don\'t get "cross-filesystem link" errors later.)
				tmpdir=$(mktemp -d $tmpl) || exit
			esac

			# Subsequent invocations of mktemp always get the same value for RANDOM because
			# it\'s used in a subshell. To get a different value each time, use the PID of the
			# current subshell (which we can only obtain by launching another shell and getting
			# it to tell its parent PID). This drastically speeds up mktemp-stresstest.sh.
			i=$(( ${RANDOM:-$$} * mypid ))
			tsuf=$(PATH=$DEFPATH command printf %0${tlen}X $i) || exit 1 "mktemp: system 'printf' command failed"

			# Atomically try to create the file or directory.
			# If it fails, that can mean two things: the file already existed or there was a fatal error.
			# Only if and when it fails, check for fatal error conditions, and try again if there are none.
			# (Checking before trying would cause a race condition, risking an infinite loop here.)
			until	tmpfile=$tmpl$tsuf
				case ${_Msh_mTo_d+d}${_Msh_mTo_F+F} in
				( d )	PATH=$DEFPATH command mkdir $tmpfile 2>/dev/null ;;
				( F )	PATH=$DEFPATH command mkfifo $tmpfile 2>/dev/null ;;
				( '' )	: >| $tmpdir/file &&
					not is present $tmpfile &&	# race condition between this and next line
					PATH=$DEFPATH command ln $tmpdir/file $tmpfile &&
					if is reg $tmpfile; then	# success
						PATH=$DEFPATH command rm $tmpdir/file
					else	# race lost (very unlikely but possible): $tmpfile is
						# a directory or a symlink to a directory. Recover.
						PATH=$DEFPATH command rm -f $tmpfile/file 2>/dev/null
						! :			# try again
					fi ;;
				( * )	exit 1 'mktemp: internal error' ;;
				esac
			do
				# check for fatal error conditions
				# (note: 'exit' will exit from this subshell only)
				case $? in
				( 126 )	exit 1 "mktemp: system error: could not invoke command" ;;
				( 127 ) exit 1 "mktemp: system error: command not found" ;;
				esac
				case $tmpl in
				( */* )	is -L dir ${tmpl%/*} || exit 1 "mktemp: not a directory: ${tmpl%/*}"
					can write ${tmpl%/*} || exit 1 "mktemp: directory not writable: ${tmpl%/*}" ;;
				( * )	can write . || exit 1 "mktemp: directory not writable: $PWD" ;;
				esac
				# none found: try again
				case ${RANDOM+s} in
				( s )	i=$(( $RANDOM * $RANDOM )) ;;
				( * )	let "i-=1" ;;
				esac
				tsuf=$(PATH=$DEFPATH command printf %0${tlen}X $i) \
				|| exit 1 "mktemp: system 'printf' command failed"
			done
			case ${_Msh_mTo_Q+y} in
			( y )	shellquote -f tmpfile
				put "$tmpfile " ;;
			( * )	putln $tmpfile ;;
			esac

			case ${_Msh_mTo_d+d}${_Msh_mTo_F+F} in
			( '' )	PATH=$DEFPATH command rmdir $tmpdir & ;;
			esac
		done

	) || die || return
	isset _Msh_mTo_Q && REPLY=${REPLY% }	# remove extra trailing space
	isset _Msh_mTo_s && unset -v _Msh_mTo_s || putln "$REPLY"
	if let "_Msh_mTo_C > 0"; then
		unset -v _Msh_mT_qnames
		# Push cleanup trap: first generate safe arguments for 'rm -rf'.
		if isset _Msh_mTo_Q; then
			# any number of shellquoted filenames
			_Msh_mT_qnames=$REPLY
		elif let "${#}==1"; then
			# single non-shellquoted filename
			_Msh_mT_qnames=$REPLY
			shellquote _Msh_mT_qnames
		else
			# multiple non-shellquoted newline-separated filenames, guaranteed no whitespace
			while IFS='' read -r _Msh_mT_f; do
				shellquote _Msh_mT_f
				_Msh_mT_qnames=${_Msh_mT_qnames:+$_Msh_mT_qnames }${_Msh_mT_f}
			done <<-EOF
			$REPLY
			EOF
		fi
		if isset -i; then
			# On interactive shells, EXIT is the only cleanup trap that makes sense.
			pushtrap "PATH=\$DEFPATH command rm -rf ${_Msh_mT_qnames}" EXIT
		elif let "_Msh_mTo_C > 2"; then
			pushtrap "PATH=\$DEFPATH command rm -rf ${_Msh_mT_qnames}" INT PIPE TERM EXIT DIE
		elif let "_Msh_mTo_C > 1"; then
			pushtrap "PATH=\$DEFPATH command rm -rf ${_Msh_mT_qnames}" INT PIPE TERM EXIT
			_Msh_mT_qnames="${CCn}mktemp: Leaving temp item(s): ${_Msh_mT_qnames}"
			shellquote _Msh_mT_qnames
			pushtrap "putln ${_Msh_mT_qnames} 1>&2" DIE
		else
			pushtrap "PATH=\$DEFPATH command rm -rf ${_Msh_mT_qnames}" PIPE TERM EXIT
			_Msh_mT_qnames="${CCn}mktemp: Leaving temp item(s): ${_Msh_mT_qnames}"
			shellquote _Msh_mT_qnames
			pushtrap "putln ${_Msh_mT_qnames} 1>&2" INT DIE
		fi
		unset -v _Msh_mT_qnames
	fi
	unset -v _Msh_mTo_d _Msh_mTo_Q _Msh_mTo_F _Msh_mTo_C || :	# BUG_UNSETFAIL compat
}

fi

unset -v _Msh_test

if thisshellhas ROFUNC; then
	readonly -f mktemp
fi
