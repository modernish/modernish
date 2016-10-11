#! /module/for/moderni/sh

# modernish sys/dir/traverse
#
# traverse: Recursively walk through a directory, executing a command for
# each file found. Cross-platform, robust replacement for 'find'. Since the
# command name can be a shell function, any functionality of 'find' and
# anything else can be programmed in the shell language.
#
# Unlike with 'find', any weird characters in file names (including
# whitespace and even newlines) "just work" as expected, provided 'use safe'
# is invoked or shell expansions are quoted. This avoids many hairy edge
# cases with 'find' while remaining compatible with all POSIX systems.
#
# Usage: traverse [ -d ] [ -X ] <dirname> <commandname>
#
# traverse calls <commandname>, once for each file found within the
# directory <dirname>, with one parameter containing the full pathname
# relative to <dirname>. Any directories found within are automatically
# entered and traversed recursively unless <commandname> exits with status
# 1. Symlinks to directories are not followed.
#
# find's '-prune' functionality is implemented by testing the command's exit
# status. If the command indicated exits with status 1 for a directory, this
# means: do not traverse the directory in question. For other types of files,
# exit status 1 is the same as 0 (success). Exit status 2 means: stop the
# execution of 'traverse' and resume program execution. An exit status greater
# than 2 indicates system failure and causes the program to abort.
#
# find's '-depth' functionality is implemented using the -d option. By default,
# 'traverse' handles directories first, before their contents. The -d option
# causes depth-first traversal, so all entries in a directory will be acted on
# before the directory itself. This applies recursively to subdirectories. That
# means depth-first traversal is incompatible with pruning, so returning status
# 1 for directories will have no effect.
#
# xargs-like functionality is implemented using the -X option. As many items
# as possible are saved up before being passed to the command all at once.
# This is also incompatible with pruning. Unlike 'xargs', the command is only
# executed if at least one item was found for it to handle.
#	(TODO: need options for limiting max depth, specifying file type,
#	and [if possible] avoiding crossing file systems.)
#
# Inspired by myfind() in Rich's sh tricks, but much improved and extended
# (no forking of subshells, no change of working directory, pruning,
# depth-first traversal, failure handling, xargs-like functionality).
#
# --- begin license ---
# Copyright (c) 2016 Martijn Dekker <martijn@inlv.org>, Groningen, Netherlands
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
# --- end license ---

# Main function.
traverse() {
	unset -v _Msh_trVo_d _Msh_trVo_X
	while startswith "${1-}" '-'; do
		case $1 in
		( -d )	_Msh_trVo_d=y ;;
		( -X )	_Msh_trVo_X=y ;;
		( -dX | -Xd )
			_Msh_trVo_d=y; _Msh_trVo_X=y ;;
		( -- )	shift; break ;;
		( -* )	die "traverse: invalid option: $1" || return ;;
		( * )	break ;;
		esac
		shift
	done
	let "$# == 2" || die "traverse: exactly 2 non-option arguments expected, got $#" || return
	if isset _Msh_trVo_X; then
		_Msh_doTraverseX "$@"
		return
	fi
	is present "$1" || die "traverse: file not found: $1" || return
	command -v "$2" >/dev/null || die "traverse: command not found: $2" || return
	if isset _Msh_trVo_d; then
		if is -L dir "$1"; then
			_Msh_trV_C=$2
			_Msh_doTraverse "$1"
		fi
		"$2" "$1"
		case $? in
		( 0|1|2 ) ;;
		( "$SIGPIPESTATUS" ) setstatus "$SIGPIPESTATUS" ;;
		( * )	_Msh_doTraverseDie "$2" "$?" ;;
		esac
	else
		"$2" "$1"
		case $? in
		( 0 )	if is -L dir "$1"; then
				_Msh_trV_C=$2
				_Msh_doTraverse "$1"
			fi ;;
		( 1|2 )	;;
		( "$SIGPIPESTATUS" ) setstatus "$SIGPIPESTATUS" ;;
		( * )	_Msh_doTraverseDie "$2" "$?" ;;
		esac
	fi
	eval "unset -v _Msh_trV_F _Msh_trV_C _Msh_trVo_d; return $?"
}

if thisshellhas BUG_UPP; then
	_Msh_doTraverse() {
		_Msh_trV_F=$1
		case $- in
		( *f* )	set +f
			set -- "${_Msh_trV_F}"/*
			is present "$1" || shift
			set -- "${_Msh_trV_F}"/.[!.]* ${1+"$@"}
			is present "$1" || shift
			set -- "${_Msh_trV_F}"/..?* ${1+"$@"}
			is present "$1" || shift
			set -f ;;
		( * )	set -- "${_Msh_trV_F}"/*
			is present "$1" || shift
			set -- "${_Msh_trV_F}"/.[!.]* ${1+"$@"}
			is present "$1" || shift
			set -- "${_Msh_trV_F}"/..?* ${1+"$@"}
			is present "$1" || shift ;;
		esac
		if isset _Msh_trVo_d; then
			while let "$#"; do
				if is dir "$1"; then
					_Msh_doTraverse "$1" || return
				fi
				"${_Msh_trV_C}" "$1"
				case $? in
				( 0|1 )	;;
				( 2 )	return 2 ;;
				( "$SIGPIPESTATUS" ) return "$SIGPIPESTATUS" ;;
				( * )	_Msh_doTraverseDie "${_Msh_trV_C}" "$?" || return ;;
				esac
				shift
			done
		else
			while let "$#"; do
				"${_Msh_trV_C}" "$1"
				case $? in
				( 0 )	if is dir "$1"; then
						_Msh_doTraverse "$1" || return
					fi ;;
				( 1 )	;;
				( 2 )	return 2 ;;
				( "$SIGPIPESTATUS" ) return "$SIGPIPESTATUS" ;;
				( * )	_Msh_doTraverseDie "${_Msh_trV_C}" "$?" || return ;;
				esac
				shift
			done
		fi
	}
else
	# no BUG_UPP: normal version
	_Msh_doTraverse() {
		_Msh_trV_F=$1
		case $- in
		( *f* )	set +f
			set -- "${_Msh_trV_F}"/*
			is present "$1" || shift
			set -- "${_Msh_trV_F}"/.[!.]* "$@"
			is present "$1" || shift
			set -- "${_Msh_trV_F}"/..?* "$@"
			is present "$1" || shift
			set -f ;;
		( * )	set -- "${_Msh_trV_F}"/*
			is present "$1" || shift
			set -- "${_Msh_trV_F}"/.[!.]* "$@"
			is present "$1" || shift
			set -- "${_Msh_trV_F}"/..?* "$@"
			is present "$1" || shift ;;
		esac
		if isset _Msh_trVo_d; then
			while let "$#"; do
				if is dir "$1"; then
					_Msh_doTraverse "$1" || return
				fi
				"${_Msh_trV_C}" "$1"
				case $? in
				( 0|1 )	;;
				( 2 )	return 2 ;;
				( "$SIGPIPESTATUS" ) return "$SIGPIPESTATUS" ;;
				( * )	_Msh_doTraverseDie "${_Msh_trV_C}" "$?" || return ;;
				esac
				shift
			done
		else
			while let "$#"; do
				"${_Msh_trV_C}" "$1"
				case $? in
				( 0 )	if is dir "$1"; then
						_Msh_doTraverse "$1" || return
					fi ;;
				( 1 )	;;
				( 2 )	return 2 ;;
				( "$SIGPIPESTATUS" ) return "$SIGPIPESTATUS" ;;
				( * )	_Msh_doTraverseDie "${_Msh_trV_C}" "$?" || return ;;
				esac
				shift
			done
		fi
	}
fi

# Handler functions for 'traverse -X': add arguments to the command line
# buffer variable. If the length would exceed the limit, execute the command
# and save the current argument for the next round. Set a relatively safe
# limit of 64 kibicharacters for each command line; modern systems handle
# anywhere from 256 KiB to 2 MiB command lines (use 'getconf ARG_MAX') but
# not all shells handle that gracefully. Plus, in UTF-8 locales, a character
# can be up to 4 bytes...
if thisshellhas KSHARRAY ARITHCMD ARITHPP; then
	# Use these shell features for speed optimisation. Wrap the functions
	# in 'eval' to avoid syntax errors on shells without these features.
	eval '_Msh_doTraverseX() {
		unset -v _Msh_trVX_args
		_Msh_trVX_i=0
		_Msh_trVX_len=0
		_Msh_trVX_C=$2
		traverse ${_Msh_trVo_d+"-d"} "$1" _Msh_doTraverseXOne || return
		if isset _Msh_trVX_args; then
			"$2" "${_Msh_trVX_args[@]}"				# KSHARRAY
			case $? in
			( 0 | 1 | 2 ) ;;
			( "$SIGPIPESTATUS" ) setstatus "$SIGPIPESTATUS" ;;
			( * )	_Msh_doTraverseDie "$2" "$?" ;;
			esac
		fi
		eval "unset -v _Msh_trVX_C _Msh_trVX_args _Msh_trVX_i _Msh_trVX_len _Msh_trVX_e; return $?"
	}
	_Msh_doTraverseXOne() {
		if (((_Msh_trVX_len+=${#1}) <= 65536)); then			# ARITHCMD
			_Msh_trVX_args[$((_Msh_trVX_i++))]=$1			# KSHARRAY, ARITHPP
		else
			# command line is full; execute command w current args and save this arg for next round
			"${_Msh_trVX_C}" "${_Msh_trVX_args[@]}"			# KSHARRAY
			_Msh_trVX_e=$?
			unset -v _Msh_trVX_args
			_Msh_trVX_args[0]=$1					# KSHARRAY
			_Msh_trVX_len=${#1}
			_Msh_trVX_i=1
			case ${_Msh_trVX_e} in
			( 0 | 1 ) ;;
			( 2 )	return 2 ;;
			( "$SIGPIPESTATUS" ) return "$SIGPIPESTATUS" ;;
			( * )	_Msh_doTraverseDie "${_Msh_trVX_C}" "${_Msh_trVX_e}" ;;
			esac
		fi
	}'
else
	_Msh_doTraverseX() {
		_Msh_trVX_args=""
		_Msh_trVX_len=0
		_Msh_trVX_C=$2
		traverse ${_Msh_trVo_d+"-d"} "$1" _Msh_doTraverseXOne || return
		if not empty "${_Msh_trVX_args}"; then
			eval "\"\$2\"${_Msh_trVX_args}"
			case $? in
			( 0 | 1 | 2 ) ;;
			( "$SIGPIPESTATUS" ) setstatus "$SIGPIPESTATUS" ;;
			( * )	_Msh_doTraverseDie "$2" "$?" ;;
			esac
		fi
		eval "unset -v _Msh_trVX_C _Msh_trVX_args _Msh_trVX_len _Msh_trVX_a; return $?"
	}
	_Msh_doTraverseXOne() {
		# Shell-quote the argument and add it to the list
		_Msh_trVX_a=$1
		shellquote _Msh_trVX_a
		if let "(_Msh_trVX_len+=${#1}) <= 65536"; then
			_Msh_trVX_args=${_Msh_trVX_args}\ ${_Msh_trVX_a}
		else
			# command line is full; save this arg for next round and execute command w current args
			_Msh_trVX_len=${#1}
			eval "_Msh_trVX_args=\\ \${_Msh_trVX_a}; \"\${_Msh_trVX_C}\"${_Msh_trVX_args}"
			case $? in
			( 0 | 1 ) ;;
			( 2 )	return 2 ;;
			( "$SIGPIPESTATUS" ) return "$SIGPIPESTATUS" ;;
			( * )	_Msh_doTraverseDie "${_Msh_trVX_C}" "$?" ;;
			esac
		fi
	}
fi

# Helper function for 'command failed' error message.
# This function is always called from a 'case $? in' construct.
if thisshellhas BUG_CASESTAT; then
	# We'd like to report the precise exit status (> 2) of the command that died. On shells with
	# BUG_CASESTAT this is inconvenient; as a workaround you have to put "$?" into a variable before
	# invoking 'case', as "$?" is zeroed before executing any case. This would need to be done on
	# every iteration, error or not. Since 'traverse' is particularly performance-sensitive, forego
	# the workaround and just don't report the precise exit status on these shells.
	_Msh_doTraverseDie() {
		die "traverse: command failed with a status > 2: $1"
	}
else
	_Msh_doTraverseDie() {
		die "traverse: command failed with status $2: $1"
	}
fi

if thisshellhas ROFUNC; then
	readonly -f traverse _Msh_doTraverse _Msh_doTraverseX _Msh_doTraverseXOne _Msh_doTraverseDie
fi
