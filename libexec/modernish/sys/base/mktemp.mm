#! /module/for/moderni/sh

# modernish sys/base/mktemp
#
# Create one or more unique temporary files, directories or named pipes,
# atomically (i.e. avoiding race conditions) and with safe permissions.
# Usage: mktemp [ -dFsQC ] [ <template> ... ]
#	-d: Create a directory instead of a regular file.
#	-F: Create a FIFO (named pipe) instead of a regular file.
#	-s: Only store output in $REPLY, don't write to standard output.
#	-Q: Shell-quote each unit of output. Separate by spaces instead of newlines.
#	-C: Automated cleanup. Push a trap to remove the files on exit.
# Any trailing 'X' characters in the template are replaced by a random number.
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

mktemp() {
	unset -v _Msh_mTo_d _Msh_mTo_F _Msh_mTo_s _Msh_mTo_Q
	forever do
		case ${1-} in
		( -??* ) # split stacked options
			_Msh_mTo_o=${1#-}
			shift
			while not empty "${_Msh_mTo_o}"; do
				if	let "$#"	# BUG_UPP workaround, BUG_PARONEARG compat
				then	set -- "-${_Msh_mTo_o#"${_Msh_mTo_o%?}"}" "$@"
				else	set -- "-${_Msh_mTo_o#"${_Msh_mTo_o%?}"}"
				fi
				_Msh_mTo_o=${_Msh_mTo_o%?}
			done
			unset -v _Msh_mTo_o
			continue ;;
		( -[dFsQC] )
			eval "_Msh_mTo_${1#-}=''" ;;
		( -- )	shift; break ;;
		( -* )	die "mktemp: invalid option: $1" || return ;;
		( * )	break ;;
		esac
		shift
	done
	if isset _Msh_mTo_d && isset _Msh_mTo_F; then
		die "mktemp: options -d and -F are inompatible" || return
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

	REPLY=$(IFS=''; set -f -u -C	# 'use safe' - no quoting needed below; '-C' (noclobber) for atomic creation
		umask 0077		# safe perms on creation
		unset -v i tmpl tlen tsuf cmd tmpfile

		# Atomic command to create a file or directory.	
		case ${_Msh_mTo_d+d}${_Msh_mTo_F+F} in
		( d )	cmd='mkdir' ;;	# mkdir without -p fails if directory exists, which we want
		( F )	cmd='mkfifo' ;;
		( * )	cmd=': >' ;;	# due to set -C this will fail if it exists
		esac

		for tmpl do
			tlen=0
			while endswith $tmpl X; do
				tmpl=${tmpl%X}
				let "tlen+=1"
			done

			i=$(( ${RANDOM:-$$} * ${RANDOM:-${PPID:-$$}} ))
			tsuf=$i
			while let "${#tsuf}<tlen"; do
				tsuf=0$tsuf
			done

			# Atomically try to create the file or directory.
			# If it fails, that can mean two things: the file already existed or there was a fatal error.
			# Only if and when it fails, check for fatal error conditions, and try again if there are none.
			# (Checking before trying would cause a race condition, risking an infinite loop here.)
			until	tmpfile=$tmpl$tsuf
				eval "command -p $cmd \$tmpfile" 2>/dev/null
			do
				# check for fatal error conditions
				# (note: 'exit' will exit from this subshell only)
				case $? in
				( 126 )	exit 1 "mktemp: system error: could not invoke '$cmd'" ;;
				( 127 ) exit 1 "mktemp: system error: command not found: '$cmd'" ;;
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
				tsuf=$i
				while let "${#tsuf}<tlen"; do
					tsuf=0$tsuf
				done
			done
			case ${_Msh_mTo_Q+y} in
			( y )	shellquote -f tmpfile
				echo -n "$tmpfile " ;;
			( * )	print $tmpfile ;;
			esac
		done
	) || die || return
	isset _Msh_mTo_Q && REPLY=${REPLY% }	# remove extra trailing space
	isset _Msh_mTo_s && unset -v _Msh_mTo_s || print "$REPLY"
	if isset _Msh_mTo_C; then
		# Push cleanup trap: first generate safe arguments for 'rm -rf'.
		if isset _Msh_mTo_Q; then
			# any number of shellquoted filename
			_Msh_mTo_C=$REPLY
		elif let "${#}==1"; then
			# single non-shellquoted filename
			_Msh_mTo_C=$REPLY
			shellquote _Msh_mTo_C
		else
			# multiple non-shellquoted newline-separated filenames, guaranteed no whitespace
			while IFS='' read -r _Msh_mT_f; do
				shellquote _Msh_mT_f
				_Msh_mTo_C=${_Msh_mTo_C:+$_Msh_mTo_C }${_Msh_mT_f}
			done <<-EOF
			$REPLY
			EOF
		fi
		# On shells other than bash, ksh93 and mksh, EXIT traps are not executed on
		# receiving a signal, so we have to trap the appropriate signals explicitly.
		pushtrap "rm -rf ${_Msh_mTo_C}" INT PIPE TERM EXIT
	fi
	unset -v _Msh_mTo_d _Msh_mTo_Q _Msh_mTo_F _Msh_mTo_C || :	# BUG_UNSETFAIL compat
}

if thisshellhas ROFUNC; then
	readonly -f mktemp
fi
