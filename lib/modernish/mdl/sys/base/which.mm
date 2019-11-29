#! /module/for/moderni/sh
\command unalias which 2>/dev/null

# modernish sys/base/which
#
# 'which' outputs the first path of each given command, or, if given the -a,
# option, all available paths, in the given order, according to the system
# $PATH. Exits successfully if at least one path was found for each command.
#
# Results are stored in REPLY, even when operating silently, which makes it
# possible to query 'which' without forking a command substitution subshell.
#
# Usage: which [ -[apqsnQ1f] ] [ -P <number> ] <program> [ <program> ... ]
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
#	   This option modifies which's exit status behaviour: 'which -1'
#	   returns successfully if any match was found.
#	-f (force/fatal): die() if at least one of the items is not found,
#	   or (if -1 is given) if none are found.
#	-P (Path): Strip the indicated number of pathname elements starting
#	   from the right.
#	   -P1: strip /program; -P2: strip /*/program, etc.
#	   This is for determining the install prefix for an installed package.
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

use var/shellquote

which() {
	# ___begin option parser___
	# The command used to generate this parser was:
	# generateoptionparser -o -n 'apqnsQf1' -a 'P' -f 'which' -v '_Msh_WhO_'
	# Then '--help' and the extended usage message were added manually.
	unset -v _Msh_WhO_a _Msh_WhO_p _Msh_WhO_q _Msh_WhO_n _Msh_WhO_s _Msh_WhO_Q _Msh_WhO_f _Msh_WhO_1 _Msh_WhO_P
	while	case ${1-} in
		( -[!-]?* ) # split a set of combined options
			_Msh_WhO__o=$1
			shift
			while _Msh_WhO__o=${_Msh_WhO__o#?} && not str empty "${_Msh_WhO__o}"; do
				_Msh_WhO__a=-${_Msh_WhO__o%"${_Msh_WhO__o#?}"} # "
				push _Msh_WhO__a
				case ${_Msh_WhO__o} in
				( [P]* ) # split optarg
					_Msh_WhO__a=${_Msh_WhO__o#?}
					not str empty "${_Msh_WhO__a}" && push _Msh_WhO__a && break ;;
				esac
			done
			while pop _Msh_WhO__a; do
				set -- "${_Msh_WhO__a}" "$@"
			done
			unset -v _Msh_WhO__o _Msh_WhO__a
			continue ;;
		( -[apqnsQf1] )
			eval "_Msh_WhO_${1#-}=''" ;;
		( -[P] )
			let "$# > 1" || die "which: $1: option requires argument"
			eval "_Msh_WhO_${1#-}=\$2"
			shift ;;
		( -- )	shift; break ;;
		( --help )
			putln "modernish $MSH_VERSION sys/base/which" \
				"usage: which [ -apqsnQ1f ] [ -P NUM ] PROGRAM [ PROGRAM ... ]" \
				"   -a: List all executables found." \
				"   -p: Search in \$DEFPATH instead of \$PATH." \
				"   -q: Quiet: suppress all warnings." \
				"   -s: Silent. Only store filenames in REPLY." \
				"   -n: Do not write final newline." \
				"   -Q: Shell-quote each pathname. Separate by spaces." \
				"   -1: Output only the first result found." \
				"   -f: Fatal error if any not found, or with -1, if none found." \
				"   -P: Strip NUM pathname elements, starting from the right."
			return ;;
		( -* )	die "which: invalid option: $1" \
				"${CCn}usage:${CCt}which [ -apqsnQf1 ] [ -P NUM ] PROGRAM [ PROGRAM ... ]" \
				"${CCn}${CCt}which --help" || return ;;
		( * )	break ;;
		esac
	do
		shift
	done
	# ^^^ end option parser ^^^
	if isset _Msh_WhO_p; then
		_Msh_WhO_p=$DEFPATH
	else
		_Msh_WhO_p=$PATH
	fi
	if isset _Msh_WhO_P; then
		str isint "${_Msh_WhO_P}" && let "_Msh_WhO_P >= 0" ||
			die "which: -P: argument must be non-negative integer"
		let "_Msh_WhO_P > 0" || unset -v _Msh_WhO_P	# -P0 does nothing
	fi
	if isset _Msh_WhO_s; then
		if not isset _Msh_WhO_q && insubshell; then
			putln "which:  warning: 'which -s' was used in a subshell; \$REPLY will" \
				"${CCt}not survive the subshell. (Suppress this warning with -q)" 1>&2
		fi
		_Msh_WhO_q=''
	fi
	if isset _Msh_WhO_1; then
		_Msh_WhO_q=''
	fi
	let "$#" || die "which: at least 1 non-option argument expected" \
				"${CCn}usage:${CCt}which [ -apqsnQf1 ] [ -P NUM ] PROGRAM [ PROGRAM ... ]" \
				"${CCn}${CCt}which --help" || return

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
			if can exec "${_Msh_Wh_dir}/${_Msh_Wh_cmd}"; then
				case ${_Msh_Wh_dir} in
				( [!/]* | */./* | */../* | */. | */.. | *//* )
					# make the path absolute (protect possible final linefeed)
					_Msh_Wh_dir=$(command cd "${_Msh_Wh_dir}" && put "${PWD}X") || continue
					_Msh_Wh_dir=${_Msh_Wh_dir%X} ;;
				esac
				_Msh_Wh_found1=${_Msh_Wh_dir}/${_Msh_Wh_cmd}
				if isset _Msh_WhO_P; then
					_Msh_Wh_i=${_Msh_WhO_P}
					while let "(_Msh_Wh_i-=1) >= 0"; do
						_Msh_Wh_found1=${_Msh_Wh_found1%/*}
						if str empty "${_Msh_Wh_found1}"; then
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
			if isset _Msh_WhO_1; then
				_Msh_Wh_allfound=y
				if isset _Msh_WhO_f; then
					_Msh_WhO_f=''	# with -1 -f, previous not-founds are not an error
				fi
				break
			fi
		else
			unset -v _Msh_Wh_allfound
			isset _Msh_WhO_q || putln "which: no ${_Msh_Wh_cmd} in (${_Msh_Wh_paths})" 1>&2
			if isset _Msh_WhO_f; then
				shellquote -f _Msh_Wh_arg
				_Msh_WhO_f=${_Msh_WhO_f}\ ${_Msh_Wh_arg}
			fi
		fi
	done
	pop -f -u IFS

	if not isset _Msh_WhO_s && not str empty "$REPLY"; then
		put "$REPLY${_Msh_WhO_n-$CCn}"
	fi
	if not str empty "${_Msh_WhO_f-}"; then
		die "which: not found:${_Msh_WhO_f}"
	fi
	isset _Msh_Wh_allfound
	eval "unset -v _Msh_WhO_a _Msh_WhO_p _Msh_WhO_q _Msh_WhO_n _Msh_WhO_s _Msh_WhO_Q _Msh_WhO_f _Msh_WhO_1 _Msh_WhO_P \
		_Msh_Wh_allfound _Msh_Wh_found1 \
		_Msh_Wh_arg _Msh_Wh_paths _Msh_Wh_dir _Msh_Wh_cmd _Msh_Wh_i; return $?"
}

if thisshellhas ROFUNC; then
	readonly -f which
fi
