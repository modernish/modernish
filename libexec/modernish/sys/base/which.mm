#! /module/for/moderni/sh

# modernish sys/base/which
#
# 'which' outputs the first path of each given command, or, if given the -a,
# option, all available paths, in the given order, according to the system
# $PATH. Exits successfully if at least one path was found for each command,
# or unsuccessfully if none were found for any given command.
#
# This implementation is inspired by both BSD and GNU 'which'. But it has
# three unique options: -Q (shell-quoting), -1 (select one of several
# names), -P (strip to install path).
#
# A unique feature, possible because this is a shell function and not an
# external command, is that the results are also stored in the REPLY
# variable, separated by newline characters ($CCn). This is done even if -s
# (silent) is given. This makes it possible to query 'which' without forking
# a subshell.
#
# Usage: which [ -[apqsQ1] ] [ -P <number> ] <program> [ <program> ... ]
#	-a (all): List all executables found (not just the first one of each).
#	-p (path): Search default system path, not current $PATH.
#	-q (quiet): Suppress warnings.
#	-s (silent): Don't write output, only store it in $REPLY.
#	   Suppress warnings except a subshell warning.
#	-n (no newline): Suppress the final newline from the output.
#	-Q (Quote): shell-quote each unit of output. Separate by spaces
#	   instead of newlines.
#	-1 (one): Output the results for at most one of the arguments in
#	   descending order of preference: once a search succeeds, ignore
#	   the rest. Suppress warnings except a subshell warning for '-s'.
#	   This is useful for finding a command that can exist under
#	   several names, for example:
#		harden as gnutar -P $(which -1 gnutar gtar tar)
#	   This option modifies which's exit status behaviour: 'which -1'
#	   returns successfully if any match was found.
#	-P (Path): Strip the indicated number of pathname elements starting
#	   from the right.
#	   -P1: strip /program; -P2: strip /*/program, etc.
#	   This is for determining the install prefix for an installed package.
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
	# ___begin option parser___
	unset -v _Msh_WhO_a _Msh_WhO_p _Msh_WhO_q _Msh_WhO_n _Msh_WhO_s _Msh_WhO_Q _Msh_WhO_1 _Msh_WhO_P
	forever do
		case ${1-} in
		( -??* ) # split a set of combined options
			_Msh_WhO__o=${1#-}
			shift
			forever do
				case ${_Msh_WhO__o} in
				( '' )	break ;;
				# if the option requires an argument, split it and break out of loop
				# (it is always the last in a combined set)
				( [P]* )
					_Msh_WhO__a=-${_Msh_WhO__o%"${_Msh_WhO__o#?}"}
					push _Msh_WhO__a
					_Msh_WhO__o=${_Msh_WhO__o#?}
					if not empty "${_Msh_WhO__o}"; then
						_Msh_WhO__a=${_Msh_WhO__o}
						push _Msh_WhO__a
					fi
					break ;;
				esac
				# split options that do not require arguments (and invalid options) until we run out
				_Msh_WhO__a=-${_Msh_WhO__o%"${_Msh_WhO__o#?}"}
				push _Msh_WhO__a
				_Msh_WhO__o=${_Msh_WhO__o#?}
			done
			while pop _Msh_WhO__a; do
				case $# in
				( 0 ) set -- "${_Msh_WhO__a}" ;;	# BUG_UPP compat
				( * ) set -- "${_Msh_WhO__a}" "$@" ;;
				esac
			done
			unset -v _Msh_WhO__o _Msh_WhO__a
			continue ;;
		( -[apqnsQ1] )
			eval "_Msh_WhO_${1#-}=''" ;;
		( -[P] )
			let "$# > 1" || die "which: $1: option requires argument" || return
			eval "_Msh_WhO_${1#-}=\$2"
			shift ;;
		( -- )	shift; break ;;
		( -* )	die "which: invalid option: $1" || return ;;
		( * )	break ;;
		esac
		shift
	done
	# ^^^ end option parser ^^^
	if isset _Msh_WhO_p; then
		_Msh_WhO_p=$DEFPATH
	else
		_Msh_WhO_p=$PATH
	fi
	if isset _Msh_WhO_P; then
		isint "${_Msh_WhO_P}" && let "_Msh_WhO_P >= 0" ||
			die "which: -P: argument must be non-negative integer" || return
		let "_Msh_WhO_P > 0" || unset -v _Msh_WhO_P	# -P0 does nothing
	fi
	if isset _Msh_WhO_s; then
		if not isset _Msh_WhO_q && insubshell; then
			putln "which:  warning: 'which -s' in a subshell does nothing unless you act" \
				"${CCt}on its exit status or use \$REPLY within the same subshell." \
				"${CCt}(suppress this warning with -q)" 1>&2
		fi
		_Msh_WhO_q=''
	fi
	if isset _Msh_WhO_1; then
		_Msh_WhO_q=''
	fi
	let "$#" || die "which: at least 1 non-option argument expected" || return

	push -f -u IFS
	set -f -u; IFS=''	# 'use safe'
	_Msh_Wh_allfound=y
	unset -v REPLY		# BUG_ARITHTYPE compat
	REPLY=''
	for _Msh_Wh_arg do
		case ${_Msh_Wh_arg} in
		# if some path was given, search only it.
		( */* )	_Msh_Wh_paths=${_Msh_Wh_arg%/*}
			_Msh_Wh_cmd=${_Msh_Wh_arg##*/} ;;
		# if only a command was given, search all paths in $PATH or (if -p was given) the default path
		( * )	_Msh_Wh_paths=${_Msh_WhO_p}
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
								if not isset _Msh_WhO_q; then
									put "which: warning: found" \
									"${_Msh_Wh_dir}/${_Msh_Wh_cmd} but can't strip" \
									"$((_Msh_WhO_P)) path elements from it${CCn}" 1>&2
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
		if isset _Msh_Wh_found1; then
			isset _Msh_WhO_1 && _Msh_Wh_allfound=y && break
		else
			unset -v _Msh_Wh_allfound
			isset _Msh_WhO_q || putln "which: no ${_Msh_Wh_cmd} in (${_Msh_Wh_paths})" 1>&2
		fi
	done
	pop -f -u IFS

	if not isset _Msh_WhO_s && not empty "$REPLY"; then
		put "$REPLY${_Msh_WhO_n-$CCn}"
	fi
	isset _Msh_Wh_allfound
	eval "unset -v _Msh_WhO_a _Msh_WhO_p _Msh_WhO_q _Msh_WhO_n _Msh_WhO_s _Msh_WhO_Q _Msh_WhO_1 _Msh_WhO_P \
		_Msh_Wh_allfound _Msh_Wh_found1 \
		_Msh_Wh_arg _Msh_Wh_paths _Msh_Wh_dir _Msh_Wh_cmd _Msh_Wh_i; return $?"
}

if thisshellhas ROFUNC; then
	readonly -f which
fi
