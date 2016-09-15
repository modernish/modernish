#! /module/for/moderni/sh

# modernish sys/baseutils
# This module provides consistent versions of certain essential, but
# non-standard utilities. They provide different command line syntaxes on
# different systems or may not be available on all systems. Since POSIX
# hasn't standardised these, this module provides a consistent version of
# these utilities to modernish scripts on all platforms.
#
# So far, this module has:
#	- readlink
#	- which
#	- mktemp
#	- yes
#
# TODO:
#	- seq
#	- option like GNU --reference for chown/chmod
#	- column
#	- unified interface to BSD and Linux 'stat'
#	- ...
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

# --------

# 'readlink', read the target of a symbolic link, is a very useful but
# non-standard command that varies widely across system. Some systems don't
# have it and the options are not the same everywhere. The BSD/Mac OS X
# version is not robust with trailing newlines in link targets. So here
# is a cross-platform consistent 'readlink'.
#
# Additional benefit: this implementation stores the link target in $REPLY,
# including any trailing newlines. This means that
#	readlink "$file"
#	do_stuff "$REPLY"
# is more robust than
#	do_stuff "$(readlink "$file")"
# (Remember that the latter form, using a command substitution, involves
# forking a subshell, so the changes to the REPLY variable are lost.)
#
# Note: if more than one argument is given, the links are stored in REPLY
# separated by newlines, so using more than one argument is not robust
# by default. To deal with this, add '-Q' for shell-quoted output and
# use something like 'eval' to parse the output as proper shell arguments.
#
# Usage:
#	readlink [ -nsfQ ] <file> [ <file> ... ]
#	-n: don't output trailing newline
#	-s: don't output anything (still store in REPLY)
#	-f: canonicalize path and follow all symlinks encountered (all but
#	    the last component must exist)
#	-Q: shell-quote each item of output; separate multiple items with
#	    spaces instead of newlines
#
# Note: the -n option works differently from both BSD and GNU 'readlink'. The
# BSD version removes *all* newlines, which makes the output for multiple
# arguments useless, as there is no separator. The GNU version ignores the
# -n option if there are multiple arguments. The modernish -n option acts
# consistently: it removes the final newline only, so multiple arguments are
# still separated by newlines.
#
# TODO: implement '-e' and '-m' as in GNU readlink
if command -v readlink >/dev/null 2>&1; then
	# Provide cross-platform interface to system 'readlink'. This command
	# is not standardised. The one invocation that seems to be consistent
	# across systems (even with edge cases like trailing newlines in link
	# targets) is "readlink -n $file" with one argument, so we use that.
	_Msh_doReadLink() {
		is sym "$1" || return 0
		# Defeat trimming of trailing newlines in command
		# substitution with a protector character.
		_Msh_rL_F=$(command readlink -n -- "$1" && command -p echo X) \
		|| die "readlink: system command 'readlink -n -- \"$1\"' failed" || return
		# Remove protector character.
		_Msh_rL_F=${_Msh_rL_F%X}
	}
else
	# No system 'readlink": fallback to 'ls -ld'.
	_Msh_doReadLink() {
		is sym "$1" || return 0
		# Parse output of 'ls -ld', which prints symlink target after ' -> '.
		# Parsing 'ls' output is hairy, but we can use the fact that the ' -> '
		# separator is standardised[*]. Defeat trimming of trailing newlines
		# in command substitution with a protector character.
		# [*] http://pubs.opengroup.org/onlinepubs/9699919799/utilities/ls.html#tag_20_73_10
		_Msh_rL_F=$(command -p ls -ld -- "$1" && command -p echo X) \
		|| die "readlink: system command 'ls -ld -- \"$1\"' failed" || return
		# Remove single newline added by 'ls' and protector character.
		_Msh_rL_F=${_Msh_rL_F%"$CCn"X}
		# Remove 'ls' output except for link target. Include filename $1 in
		# search pattern so this should even work if either the link name or
		# the target contains ' -> '.
		_Msh_rL_F=${_Msh_rL_F#*" $1 -> "}
	}
fi
readlink() {
	unset -v REPLY _Msh_rL_s _Msh_rL_Q _Msh_rL_f
	_Msh_rL_err=0 _Msh_rL_n=$CCn
	forever do
		case ${1-} in
		( -??* ) # split stacked options
			_Msh_rL_o=${1#-}
			shift
			while not empty "${_Msh_rL_o}"; do
				if	gt "$#" 0	# BUG_UPP workaround, BUG_PARONEARG compat
				then	set -- "-${_Msh_rL_o#"${_Msh_rL_o%?}"}" "$@"
				else	set -- "-${_Msh_rL_o#"${_Msh_rL_o%?}"}"
				fi
				_Msh_rL_o=${_Msh_rL_o%?}
			done
			unset -v _Msh_rL_o
			continue ;;
		( -n )	_Msh_rL_n='' ;;
		( -s )	_Msh_rL_s=y ;;
		( -f )	_Msh_rL_f=y ;;
		( -Q )	_Msh_rL_Q=y ;;
		( -- )	shift; break ;;
		( -* )	die "readlink: invalid option: $1" || return ;;
		( * )	break ;;
		esac
		shift
	done
	gt "$#" 0 || die "readlink: at least one non-option argument expected"
	REPLY=''
	for _Msh_rL_F do
		if not is sym "${_Msh_rL_F}" && not isset _Msh_rL_f; then
			_Msh_rL_err=1
			continue
		elif isset _Msh_rL_f; then
			# canonicalize (deal with relative paths: use subshell for safe 'cd')
			_Msh_rL_F=$(
				case ${_Msh_rL_F} in
				(?*/*)	command cd "${_Msh_rL_F%/*}" 2>/dev/null || \exit 0 ;;
				(/*)	command cd / ;;
				esac
				_Msh_rL_F=${_Msh_rL_F##*/}
				while _Msh_doReadLink "${_Msh_rL_F}" || \exit; do
					case ${_Msh_rL_F} in
					(?*/*)	command cd "${_Msh_rL_F%/*}" 2>/dev/null || \exit 0 ;;
					(/*)	command cd / ;;
					esac
					_Msh_rL_F=${_Msh_rL_F##*/}
					is sym "${_Msh_rL_F}" || break
				done
				_Msh_rL_D=$(pwd -P; command -p echo X)
				case ${_Msh_rL_D} in
				( /"$CCn"X )
					echo "/${_Msh_rL_F}X" ;;
				( * )	echo "${_Msh_rL_D%"$CCn"X}/${_Msh_rL_F}X" ;;
				esac
			) || return
			if empty "${_Msh_rL_F}"; then
				_Msh_rL_err=1
				continue
			fi
			_Msh_rL_F=${_Msh_rL_F%X}
		else
			# don't canonicalize
			_Msh_doReadLink "${_Msh_rL_F}" || return
		fi
		if isset _Msh_rL_Q; then
			shellquote -f _Msh_rL_F
			REPLY=${REPLY:+$REPLY }${_Msh_rL_F}
		else
			REPLY=${REPLY:+$REPLY$CCn}${_Msh_rL_F}
		fi
	done
	if not empty "$REPLY" && not isset _Msh_rL_s; then
		echo -n "${REPLY}${_Msh_rL_n}"
	fi
	eval "unset -v _Msh_rL_n _Msh_rL_s _Msh_rL_f _Msh_rL_Q _Msh_rL_F _Msh_rL_err; return ${_Msh_rL_err}"
}

# --------

# 'which' outputs the first path of each given command, or, if given the -a,
# option, all available paths, in the given order, according to the system
# $PATH. Exits successfully if at least one path was found for each command,
# or unsuccessfully if none were found for any given command. This
# implementation is inspired by both BSD and GNU 'which'. But it has two
# unique options: -Q (shell-quoting) and -P (strip to install path).
#
# A unique feature, possible because this is a shell function and not an
# external command, is that the results are also stored in the REPLY
# variable, separated by newline characters ($CCn). This is done even if -s
# (silent) is given. This makes it possible to query 'which' without forking
# a subshell.
#
# Usage: which [ -a ] [ -s ] [ -Q ] [ -P <number> ] <program> [ <program> ... ]
#	-a: List all executables found (not just the first one of each).
#	-s: Only store output in $REPLY, don't write any output or warning.
#	-Q: shell-quote each unit of output. Separate by spaces instead of newlines.
#	-P: Strip the indicated number of pathname elements starting from right.
#	    -P1: strip /program; -P2: strip /*/program, etc.
#	    This is for determining the install prefix for an installed package.

which() {
	unset -v REPLY _Msh_WhO_a _Msh_WhO_s _Msh_WhO_Q _Msh_WhO_P

	# TODO: This option parsing code got rather involved. Make a generic library
	# function out of it.
	forever do
		case ${1-} in
		( -??* ) # split stacked options, handling arguments correctly
			_Msh_Wh_st=${1#-}	# stacked options
			_Msh_Wh_sp=		# split options, shellquoted
			shift
			storeparams _Msh_Wh_restp
			while not empty "${_Msh_Wh_st}"; do
				case ${_Msh_Wh_st} in
				# if the option requires an argument, split it and break out of loop
				# (it is always the last in a series of stacked options)
				( P* )	_Msh_Wh_o=${_Msh_Wh_st%"${_Msh_Wh_st#?}"}	# "
					shellquote _Msh_Wh_o
					_Msh_Wh_st=${_Msh_Wh_st#?}
					not empty "${_Msh_Wh_st}" && shellquote _Msh_Wh_st
					_Msh_Wh_sp="${_Msh_Wh_sp} -${_Msh_Wh_o} ${_Msh_Wh_st}"
					break ;;
				esac
				# split options that do not require arguments until we run out
				_Msh_Wh_o=${_Msh_Wh_st%"${_Msh_Wh_st#?}"}	# "
				shellquote _Msh_Wh_o
				_Msh_Wh_sp="${_Msh_Wh_sp} -${_Msh_Wh_o}"
				_Msh_Wh_st=${_Msh_Wh_st#?}
			done
			eval "set -- ${_Msh_Wh_sp} ${_Msh_Wh_restp}"
			unset -v _Msh_Wh_st _Msh_Wh_sp _Msh_Wh_restp _Msh_Wh_o
			continue ;;
		( -a )	_Msh_WhO_a=y ;;
		( -s )	_Msh_WhO_s=y ;;
		( -Q )	_Msh_WhO_Q=y ;;
		( -P )	gt "$#" 0 || die "which: -P: option requires argument" || return
			shift
			_Msh_WhO_P=$1 ;;
		( -- )	shift; break ;;
		( -* )	die "which: invalid option: $1" || return ;;
		( * )	break ;;
		esac
		shift
	done
	gt "$#" 0 || die "which: at least 1 non-option argument expected" || return

	if isset _Msh_WhO_P; then
		isint "${_Msh_WhO_P}" && ge _Msh_WhO_P 0 ||
			die "which: -P: argument must be non-negative integer" || return
		gt _Msh_WhO_P 0 || unset -v _Msh_WhO_P	# -P0 does nothing
	fi

	push -f -u IFS
	set -f -u; IFS=''	# 'use safe'
	_Msh_Wh_allfound=y
	REPLY=''
	for _Msh_Wh_arg do
		case ${_Msh_Wh_arg} in
		# if some path was given, search only it.
		( */* )	_Msh_Wh_paths=${_Msh_Wh_arg%/*}
			_Msh_Wh_cmd=${_Msh_Wh_arg##*/} ;;
		# if only a command was given, search all paths in $PATH
		( * )	_Msh_Wh_paths=$PATH
			_Msh_Wh_cmd=${_Msh_Wh_arg} ;;
		esac
		unset -v _Msh_Wh_found1

		IFS=':'
		for _Msh_Wh_dir in ${_Msh_Wh_paths}; do
			if is -L reg "${_Msh_Wh_dir}/${_Msh_Wh_cmd}" && can exec "${_Msh_Wh_dir}/${_Msh_Wh_cmd}"; then
				_Msh_Wh_found1=${_Msh_Wh_dir}/${_Msh_Wh_cmd}
				if isset _Msh_WhO_P; then
					_Msh_Wh_i=${_Msh_WhO_P}
					while ge _Msh_Wh_i-=1 0; do
						_Msh_Wh_found1=${_Msh_Wh_found1%/*}
						if empty "${_Msh_Wh_found1}"; then
							if gt _Msh_Wh_i 0; then
								if not isset _Msh_WhO_s; then
									echo "which: warning: found" \
									"${_Msh_Wh_dir}/${_Msh_Wh_cmd} but can't strip" \
									"$((_Msh_WhO_P)) path elements from it" 1>&2
								fi
								unset -v _Msh_Wh_allfound
								continue 2
							else
								_Msh_Wh_found1=/
							fi
							break
						fi
					done
				fi
				if isset _Msh_WhO_Q; then
					shellquote -f _Msh_Wh_found1
					REPLY=${REPLY:+$REPLY }${_Msh_Wh_found1}
				else
					REPLY=${REPLY:+$REPLY$CCn}${_Msh_Wh_found1}
				fi
				isset _Msh_WhO_a || break
			fi
		done
		if not isset _Msh_Wh_found1; then
			unset -v _Msh_Wh_allfound
			isset _Msh_WhO_s || print "which: no ${_Msh_Wh_cmd} in (${_Msh_Wh_paths})" 1>&2
		fi
	done
	pop -f -u IFS

	if not isset _Msh_WhO_s && not empty "$REPLY"; then
		print "$REPLY"
	fi
	isset _Msh_Wh_allfound
	eval "unset -v _Msh_WhO_a _Msh_WhO_s _Msh_Wh_allfound _Msh_Wh_found1 \
		_Msh_Wh_arg _Msh_Wh_paths _Msh_Wh_dir _Msh_Wh_cmd _Msh_Wh_i; return $?"
}

# --------

# Create one or more unique temporary files, directories or named pipes,
# atomically (i.e. avoiding race conditions) and with safe permissions.
# Usage: mktemp [ -dFsQ ] [ <template> ... ]
#	-d: Create a directory instead of a regular file.
#	-F: Create a FIFO (named pipe) instead of a regular file.
#	-s: Only store output in $REPLY, don't write to standard output.
#	-Q: Shell-quote each unit of output. Separate by spaces instead of newlines.
# Any trailing 'X' characters in the template are replaced by a random number.
# The -u option from other mktemp implementations is not supported. It's unsafe.
# The -q option is also not supported: this mktemp dies (kills the program) if
# an error occurs, so suppressing the error message would not make sense.
mktemp() {
	unset -v _Msh_mTo_d _Msh_mTo_F _Msh_mTo_s _Msh_mTo_Q
	forever do
		case ${1-} in
		( -??* ) # split stacked options
			_Msh_mTo_o=${1#-}
			shift
			while not empty "${_Msh_mTo_o}"; do
				if	gt "$#" 0	# BUG_UPP workaround, BUG_PARONEARG compat
				then	set -- "-${_Msh_mTo_o#"${_Msh_mTo_o%?}"}" "$@"
				else	set -- "-${_Msh_mTo_o#"${_Msh_mTo_o%?}"}"
				fi
				_Msh_mTo_o=${_Msh_mTo_o%?}
			done
			unset -v _Msh_mTo_o
			continue ;;
		( -[dFsQ] )
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
	unset -v _Msh_mTo_d _Msh_mTo_Q
	isset _Msh_mTo_s && unset -v _Msh_mTo_s || print "$REPLY"
}

# --------

# Output a string (default: 'y') repeatedly until killed.
# Useful to automate a command requiring interactive confirmation,
# e.g.: yes | some_command_that_asks_for_confirmation
yes() {
	case $# in
	( 0 )	forever do print y; done ;;
	( 1 )	forever do print "$1"; done ;;
	( * )	die "yes: too many arguments (max. 1)" ;;
	esac
}
