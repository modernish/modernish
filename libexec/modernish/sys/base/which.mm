#! /module/for/moderni/sh

# modernish sys/base/which
#
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
		( -P )	let "$#" || die "which: -P: option requires argument" || return
			shift
			_Msh_WhO_P=$1 ;;
		( -- )	shift; break ;;
		( -* )	die "which: invalid option: $1" || return ;;
		( * )	break ;;
		esac
		shift
	done
	let "$#" || die "which: at least 1 non-option argument expected" || return

	if isset _Msh_WhO_P; then
		isint "${_Msh_WhO_P}" && let "_Msh_WhO_P >= 0" ||
			die "which: -P: argument must be non-negative integer" || return
		let "_Msh_WhO_P > 0" || unset -v _Msh_WhO_P	# -P0 does nothing
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
					while let "(_Msh_Wh_i-=1) >= 0"; do
						_Msh_Wh_found1=${_Msh_Wh_found1%/*}
						if empty "${_Msh_Wh_found1}"; then
							if let "_Msh_Wh_i > 0"; then
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

if thisshellhas ROFUNC; then
	readonly -f which
fi
