#! /module/for/moderni/sh

# modernish sys/baseutils
# This module provides consistent versions of certain essential, but
# non-standard utilities. They provide different command line syntaxes on
# different systems or may not be available on all systems. Since POSIX
# hasn't standardised these, this module provides a consistent interface to
# these utilities on all platforms.
#
# So far, this module has:
#	- readlink
#	- which
#
# TODO:
#	- mktemp
#	- seq
#	- yes
#	- option like GNU --reference for chown/chmod
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
# Note: the -n option works differently from both BSD and GNU 'which'. The
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
		issym "$1" || return 0
		# Defeat trimming of trailing newlines in command
		# substitution with a protector character.
		_Msh_rL_F=$(command readlink -n -- "$1" && echo X) \
		|| die "readlink: system command 'readlink -n -- \"$1\"' failed" || return
		# Remove protector character.
		_Msh_rL_F=${_Msh_rL_F%X}
	}
else
	# No system 'readlink": fallback to 'ls -ld'.
	_Msh_doReadLink() {
		issym "$1" || return 0
		# Parse output of 'ls -ld', which prints symlink target after ' -> '.
		# Parsing 'ls' output is hairy, but we can use the fact that the ' -> '
		# separator is standardised[*]. Defeat trimming of trailing newlines
		# in command substitution with a protector character.
		# [*] http://pubs.opengroup.org/onlinepubs/9699919799/utilities/ls.html#tag_20_73_10
		_Msh_rL_F=$(command -p ls -ld -- "$1" && echo X) \
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
	_Msh_rL_err=0 _Msh_rL_n='\n'
	while :; do
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
		if not issym "${_Msh_rL_F}" && not isset _Msh_rL_f; then
			_Msh_rL_err=1
			continue
		elif isset _Msh_rL_f; then
			# canonicalize (deal with relative paths: use subshell for safe 'cd')
			_Msh_rL_F=$(
				case ${_Msh_rL_F} in
				( */* )	command cd "${_Msh_rL_F%/*}" 2>/dev/null || \exit 0 ;;
				esac
				_Msh_rL_F=${_Msh_rL_F##*/}
				while _Msh_doReadLink "${_Msh_rL_F}" || \exit; do
					case ${_Msh_rL_F} in
					( */* )	command cd "${_Msh_rL_F%/*}" 2>/dev/null || \exit 0 ;;
					esac
					_Msh_rL_F=${_Msh_rL_F##*/}
					issym "${_Msh_rL_F}" || break
				done
				_Msh_rL_D=$(pwd -P; echo X)
				echo "${_Msh_rL_D%"$CCn"X}/${_Msh_rL_F}X"
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
		printf "%s${_Msh_rL_n}" "$REPLY"
	fi
	eval "unset -v _Msh_rL_n _Msh_rL_s _Msh_rL_f _Msh_rL_Q _Msh_rL_F _Msh_rL_err; return ${_Msh_rL_err}"
}

# --------

# 'which' outputs the first path of each given command, or, if given the -a,
# option, all available paths, in the given order, according to the system
# $PATH. Exits successfully if at least one path was found for each command,
# or unsuccessfully if none were found for any given command. This
# implementation is inspired by both BSD and GNU 'which'.
#
# A unique feature, possible because this is a shell function and not an
# external command, is that the results are also stored in the REPLY
# variable, separated by newline characters ($CCn). This is done even if -s
# (silent) is given. This makes it possible to query 'which' without forking
# a subshell.
#
# Usage: which [ -asQ ] <programname> [ <programname> ... ]
#	-a: List all executables found (not just the first one of each).
#	-s: Only store output in $REPLY, don't write to standard output.
#	-Q: shell-quote each unit of output. Separate by spaces instead of newlines.

which() {
	unset -v REPLY _Msh_WhO_a _Msh_WhO_s _Msh_WhO_Q
	while :; do
		case ${1-} in
		( -??* ) # split stacked options
			_Msh_WhO_o=${1#-}
			shift
			while not empty "${_Msh_WhO_o}"; do
				if	gt "$#" 0	# BUG_UPP workaround, BUG_PARONEARG compat
				then	set -- "-${_Msh_WhO_o#"${_Msh_WhO_o%?}"}" "$@"
				else	set -- "-${_Msh_WhO_o#"${_Msh_WhO_o%?}"}"
				fi
				_Msh_WhO_o=${_Msh_WhO_o%?}
			done
			unset -v _Msh_WhO_o
			continue ;;
		( -a )	_Msh_WhO_a=y ;;
		( -s )	_Msh_WhO_s=y ;;
		( -Q )	_Msh_WhO_Q=y ;;
		( -- )	shift; break ;;
		( -* )	die "which: invalid option: $1" || return ;;
		( * )	break ;;
		esac
		shift
	done
	gt "$#" 0 || die "which: at least 1 non-option argument expected" || return

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
			if isreg -L "${_Msh_Wh_dir}/${_Msh_Wh_cmd}" && canexec "${_Msh_Wh_dir}/${_Msh_Wh_cmd}"; then
				_Msh_Wh_found1=y
				if isset _Msh_WhO_Q; then
					_Msh_WhO_Q=${_Msh_Wh_dir}/${_Msh_Wh_cmd}
					shellquote -f _Msh_WhO_Q
					REPLY=${REPLY:+$REPLY }${_Msh_WhO_Q}
				else
					REPLY=${REPLY:+$REPLY$CCn}${_Msh_Wh_dir}/${_Msh_Wh_cmd}
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

	isset _Msh_WhO_s || print "$REPLY"
	isset _Msh_Wh_allfound
	eval "unset -v _Msh_WhO_a _Msh_WhO_s _Msh_Wh_allfound _Msh_Wh_found1 \
		_Msh_Wh_arg _Msh_Wh_paths _Msh_Wh_dir _Msh_Wh_cmd; return $?"
}
