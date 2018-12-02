#! /module/for/moderni/sh
unalias traverse _Msh_doTraverse _Msh_doTraverseDepthFirst _Msh_doTraverseDie _Msh_doTraverseX _Msh_doTraverseXOne

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
# Usage: traverse [ -d ] [ -F ] [ -X ] <dirname> <commandname>
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
# find's '-xdev' functionality is implemented using the -F option. If this
# is given, `traverse` will not descend into directories that are on
# another file system than that of the directory given in the argument.
#
# xargs-like functionality is implemented using the -X option. As many items
# as possible are saved up before being passed to the command all at once.
# This is also incompatible with pruning. Unlike 'xargs', the command is only
# executed if at least one item was found for it to handle.
#	(TODO: need options for limiting max depth, specifying file type)
#
# Inspired by myfind() in Rich's sh tricks, but much improved and extended
# (no forking of subshells, no change of working directory, pruning,
# depth-first traversal, failure handling, xargs-like functionality).
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

unset -v _Msh_trVX_C _Msh_trVo_d _Msh_trVo_X _Msh_trVo_F _Msh_trV_F _Msh_trV_C

# Main function.
traverse() {
	push _Msh_trVo_d _Msh_trVo_X _Msh_trVo_F _Msh_trV_F _Msh_trV_C
	# ___begin option parser___
	unset -v _Msh_trVo_d _Msh_trVo_X
	forever do
		case ${1-} in
		( -[!-]?* ) # split a set of combined options
			_Msh_trVo__o=${1#-}
			shift
			while not empty "${_Msh_trVo__o}"; do
				set -- "-${_Msh_trVo__o#"${_Msh_trVo__o%?}"}" "$@"	#"
				_Msh_trVo__o=${_Msh_trVo__o%?}
			done
			unset -v _Msh_trVo__o
			continue ;;
		( -[dXF] )
			eval "_Msh_trVo_${1#-}=''" ;;
		( -- )	shift; break ;;
		( -* )	die "traverse: invalid option: $1" || return ;;
		( * )	break ;;
		esac
		shift
	done
	# ^^^ end option parser ^^^
	let "$# == 2" || die "traverse: exactly 2 non-option arguments expected, got $#" || return
	if isset _Msh_trVo_X
	then	# Xargs-like mode. This recursively does a regular 'traverse'
		# with a special handler function that saves up the arguments.
		if isset _Msh_trVX_C; then
			die "Sorry, recursive 'traverse -X' is not supported" || return
		fi
		_Msh_doTraverseX "$@"
		pop _Msh_trVo_d _Msh_trVo_X _Msh_trV_F _Msh_trV_C
		return
	fi
	is present "$1" || die "traverse: file not found: $1" || return
	command -v "$2" >/dev/null || die "traverse: command not found: $2" || return
	if isset _Msh_trVo_F
	then	# Don't cross devices.
		_Msh_trVo_F=$1
	fi
	if isset _Msh_trVo_d
	then	# Depth-first traversal.
		if is -L dir "$1"; then
			_Msh_trV_C=$2
			_Msh_doTraverseDepthFirst "$1"
		fi
		"$2" "$1"
		case $? in
		( 0|1|2 ) ;;
		( "$SIGPIPESTATUS" ) setstatus "$SIGPIPESTATUS" ;;
		( * )	_Msh_doTraverseDie "$2" "$?" ;;
		esac
	else	# Normal traversal.
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
	pop --keepstatus _Msh_trVo_d _Msh_trVo_X _Msh_trVo_F _Msh_trV_F _Msh_trV_C
}

# Define a couple of handler functions for normal traversal and depth traversal.
# Piece them together from various bits of shell-specific code.
#
# First, define a code snippet for globbing used in the functions further below.
# 'traverse' is fundamentally based on shell globbing (pathname expansion): we
# use special cross-platform globbing voodoo to get the names of all the
# files/directories/etc. in a particular directory into the positional
# parameters (PPs), so we can iterate through them.
# - Simple '*' does not work to get all the files because it excludes files
#   starting with '.'. So dot-files must be globbed separately ('.*'), but some
#   shells include the navigation shortcuts '.' and '..' in expanding that; we
#   have to exclude those. So glob in three stages: (1) ..* excluding '..'
#   itself; (2) .* excluding '.' and ..*; and (3) * (which equals [!.]*).
#   Do these in reverse order as each stage is inserted at start of PPs.
# - If no file matches a pattern, the unresolved pattern yields the pattern
#   itself as a single argument. Deal with that by simply checking whether the
#   file exists and, if not, shifting it out of the positional parameters.
#   (Note: bash 'nullglob' option (in 'shopt') would totally break this.)
if thisshellhas --kw=[[ ARITHCMD
then	# Directly use '[[' as a speed optimisation. Note that, unlike with 'is present' and 'is dir',
	# we'll have to deal with its bizarre logic inherited from 'test'/'[': '-e' yields false for
	# broken symlinks, so test symlinks separately; '-d' yields true if it's a directory _or_ a
	# symlink to a directory, so test against symlinks. This optimisation is primarily for the benefit
	# of bash, which is very slow (esp. calling shell functions) and can use all the speed it can get.
	_Msh_traverse_globAllFilesInDir='set -- "${_Msh_trV_F}"/*
			[[ -e $1 || -L $1 ]] || shift
			set -- "${_Msh_trV_F}"/.[!.]* "$@"
			[[ -e $1 || -L $1 ]] || shift
			set -- "${_Msh_trV_F}"/..?* "$@"
			[[ -e $1 || -L $1 ]] || shift'
	eval '_Msh_doTraverse() {
		_Msh_trV_F=$1
		case $- in
		( *f* )	set +f
			'"${_Msh_traverse_globAllFilesInDir}"'
			set -f ;;
		( * )	'"${_Msh_traverse_globAllFilesInDir}"' ;;
		esac
		while (($#)); do		# ARITHCMD
			"${_Msh_trV_C}" "$1"
			case $? in
			( 0 )	if [[ -d $1 && ! -L $1 ]]; then
					case ${_Msh_trVo_F+s} in
					( s )	if not is onsamefs "${_Msh_trVo_F}" "$1"; then
							shift
							continue
						fi ;;
					esac
					_Msh_doTraverse "$1" || return
				fi ;;
			( 1 )	;;
			( 2 )	return 2 ;;
			( "$SIGPIPESTATUS" ) return "$SIGPIPESTATUS" ;;
			( * )	_Msh_doTraverseDie "${_Msh_trV_C}" "$?" || return ;;
			esac
			shift
		done
	}
	_Msh_doTraverseDepthFirst() {
		_Msh_trV_F=$1
		case $- in
		( *f* )	set +f
			'"${_Msh_traverse_globAllFilesInDir}"'
			set -f ;;
		( * )	'"${_Msh_traverse_globAllFilesInDir}"' ;;
		esac
		while (($#)); do		# ARITHCMD
			if [[ -d $1 && ! -L $1 ]]; then
				case ${_Msh_trVo_F+s} in
				( s )	if not is onsamefs "${_Msh_trVo_F}" "$1"; then
						"${_Msh_trV_C}" "$1"
						case $? in
						( 0|1 )	shift
							continue ;;
						( 2 )	return 2 ;;
						( "$SIGPIPESTATUS" ) return "$SIGPIPESTATUS" ;;
						( * )	_Msh_doTraverseDie "${_Msh_trV_C}" "$?" || return ;;
						esac
					fi ;;
				esac
				_Msh_doTraverseDepthFirst "$1" || return
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
	}'"$CCn"
else	# Canonical version below.
	# We don't have '[['. Just use modernish is(), because it already implements all the
	# checks and workarounds for the '['/'test' botch. Plus, simple POSIX shells without
	# '[[' (like dash, Busybox ash, FreeBSD sh) are usually pretty fast anyway.
	_Msh_traverse_globAllFilesInDir='set -- "${_Msh_trV_F}"/*
			is present "$1" || shift
			set -- "${_Msh_trV_F}"/.[!.]* "$@"
			is present "$1" || shift
			set -- "${_Msh_trV_F}"/..?* "$@"
			is present "$1" || shift'
	eval '_Msh_doTraverse() {
		_Msh_trV_F=$1
		case $- in
		( *f* )	set +f
			'"${_Msh_traverse_globAllFilesInDir}"'
			set -f ;;
		( * )	'"${_Msh_traverse_globAllFilesInDir}"' ;;
		esac
		while let "$#"; do
			"${_Msh_trV_C}" "$1"
			case $? in
			( 0 )	if is dir "$1"; then
					case ${_Msh_trVo_F+s} in
					( s )	if not is onsamefs "${_Msh_trVo_F}" "$1"; then
							shift
							continue
						fi ;;
					esac
					_Msh_doTraverse "$1" || return
				fi ;;
			( 1 )	;;
			( 2 )	return 2 ;;
			( "$SIGPIPESTATUS" ) return "$SIGPIPESTATUS" ;;
			( * )	_Msh_doTraverseDie "${_Msh_trV_C}" "$?" || return ;;
			esac
			shift
		done
	}
	_Msh_doTraverseDepthFirst() {
		_Msh_trV_F=$1
		case $- in
		( *f* )	set +f
			'"${_Msh_traverse_globAllFilesInDir}"'
			set -f ;;
		( * )	'"${_Msh_traverse_globAllFilesInDir}"' ;;
		esac
		while let "$#"; do
			if is dir "$1"; then
				case ${_Msh_trVo_F+s} in
				( s )	if not is onsamefs "${_Msh_trVo_F}" "$1"; then
						"${_Msh_trV_C}" "$1"
						case $? in
						( 0|1 )	shift
							continue ;;
						( 2 )	return 2 ;;
						( "$SIGPIPESTATUS" ) return "$SIGPIPESTATUS" ;;
						( * )	_Msh_doTraverseDie "${_Msh_trV_C}" "$?" || return ;;
						esac
					fi ;;
				esac
				_Msh_doTraverseDepthFirst "$1" || return
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
	}'"$CCn"
fi
unset -v _Msh_traverse_globAllFilesInDir

# Handler functions for 'traverse -X': add arguments to the command line
# buffer variable. If the length would exceed the limit, execute the command
# and save the current argument for the next round. Set a relatively safe
# limit of 64 kibicharacters for each command line; modern systems handle
# anywhere from 256 KiB to 2 MiB command lines (use 'getconf ARG_MAX') but
# not all shells handle that gracefully. Plus, in UTF-8 locales, a character
# can be up to 4 bytes...
if thisshellhas KSHARRAY ARITHCMD ARITHPP
then	# Use these shell features for speed optimisation. Wrap the functions
	# in 'eval' to avoid syntax errors on shells without these features.
	eval '_Msh_doTraverseX() {
		unset -v _Msh_trVX_args
		_Msh_trVX_i=0
		_Msh_trVX_len=0
		_Msh_trVX_C=$2
		traverse ${_Msh_trVo_d+"-d"} ${_Msh_trVo_F+"-F"} "$1" _Msh_doTraverseXOne || return
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
	}'"$CCn"
else	# Canonical version below.
	_Msh_doTraverseX() {
		_Msh_trVX_args=""
		_Msh_trVX_vars=""
		_Msh_trVX_i=0
		_Msh_trVX_len=0
		_Msh_trVX_C=$2
		traverse ${_Msh_trVo_d+"-d"} ${_Msh_trVo_F+"-F"} "$1" _Msh_doTraverseXOne || return
		if not empty "${_Msh_trVX_args}"; then
			eval "\"\$2\"${_Msh_trVX_args}"
			case $? in
			( 0 | 1 | 2 ) ;;
			( "$SIGPIPESTATUS" ) setstatus "$SIGPIPESTATUS" ;;
			( * )	_Msh_doTraverseDie "$2" "$?" ;;
			esac
		fi
		eval "unset -v ${_Msh_trVX_vars} _Msh_trVX_vars _Msh_trVX_C _Msh_trVX_args _Msh_trVX_i \
			_Msh_trVX_len _Msh_trVX_e; return $?"
	}
	_Msh_doTraverseXOne() {
		if let "(_Msh_trVX_len+=${#1}) <= 65536"; then
			eval "_Msh_trVX${_Msh_trVX_i}=\$1"
			_Msh_trVX_args="${_Msh_trVX_args} \"\$_Msh_trVX${_Msh_trVX_i}\""
			_Msh_trVX_vars="${_Msh_trVX_vars} _Msh_trVX${_Msh_trVX_i}"
			_Msh_trVX_i=$((_Msh_trVX_i+1))
		else
			# command line is full; execute command w current args and save this arg for next round
			eval "\"\${_Msh_trVX_C}\"${_Msh_trVX_args}"
			_Msh_trVX_e=$?
			eval "unset -v ${_Msh_trVX_vars}"
			_Msh_trVX0=$1
			_Msh_trVX_args=' "$_Msh_trVX0"'
			_Msh_trVX_vars=' _Msh_trVX0'
			_Msh_trVX_len=${#1}
			_Msh_trVX_i=1
			case ${_Msh_trVX_e} in
			( 0 | 1 ) ;;
			( 2 )	return 2 ;;
			( "$SIGPIPESTATUS" ) return "$SIGPIPESTATUS" ;;
			( * )	_Msh_doTraverseDie "${_Msh_trVX_C}" "${_Msh_trVX_e}" ;;
			esac
		fi
	}
fi

# Helper function for 'command failed' error message.
# This function is always called from a 'case $? in' construct.
if thisshellhas BUG_CASESTAT
then	# We'd like to report the precise exit status (> 2) of the command that died. On shells with
	# BUG_CASESTAT this is inconvenient; as a workaround you have to put "$?" into a variable before
	# invoking 'case', as "$?" is zeroed before executing any case. This would need to be done on
	# every iteration, error or not. Since 'traverse' is particularly performance-sensitive, forego
	# the workaround and just don't report the precise exit status on these shells.
	_Msh_doTraverseDie() {
		die "traverse: command failed with a status > 2: $1"
	}
else	# Canonical version below.
	_Msh_doTraverseDie() {
		die "traverse: command failed with status $2: $1"
	}
fi

if thisshellhas ROFUNC; then
	readonly -f traverse _Msh_doTraverse _Msh_doTraverseX _Msh_doTraverseXOne _Msh_doTraverseDie
fi
