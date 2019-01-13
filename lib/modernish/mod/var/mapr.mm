#! /module/for/moderni/sh
\command unalias mapr _Msh_mapr_ckE 2>/dev/null

# var/mapr
#
# mapr (map records): Read delimited records from the standard input, invoking
# a CALLBACK command with each input record as an argument and with up to
# QUANTUM arguments at a time. By default, an input record is one line of text.
#
# Usage:
# mapr [-d DELIM | -D] [-n COUNT] [-s COUNT] [-c QUANTUM] CALLBACK [ARG ...]
#
# Options:
#   -d DELIM	Use the single character DELIM to delimit input records,
#		instead of the newline character.
#   -P		Paragraph mode. Input records are delimited by sequences
#		consisting of a newline plus one or more blank lines, and
#		leading or trailing blank lines will not result in empty
#		records at the beginning or end of the input. Cannot be used
#		together with -d.
#   -n COUNT	Pass at most COUNT records to CALLBACK. If COUNT is 0, all
#		records are passed.
#   -s COUNT	Skip and discard the first COUNT records read.
#   -c QUANTUM	Pass at most QUANTUM arguments at a time to each call to
#		CALLBACK. If not set or 0, this is not limited except by -m.
#   -m LENGTH	Pass at most LENGTH bytes of arguments to each call to
#		CALLBACK. If not set or 0, the limit is set by the OS.
#
# Arguments:
#   CALLBACK	Call the CALLBACK command with the collected arguments each
#		time QUANTUM lines are read. The callback command may be a
#		shell function or any other kind of command. It is a fatal
#		error for the callback command to exit with a status > 0.
#   ARG		If there are extra arguments supplied on the mapr command line,
#		they will be added before the collected arguments on each
#		invocation on the callback command.
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

use sys/cmd/extern

# determine max length in bytes of arguments we can pass
_Msh_mapr_max=$(extern -p getconf ARG_MAX 2>/dev/null || putln 262144)
if not str isint "${_Msh_mapr_max}" || let "_Msh_mapr_max < 4096"; then
	putln "var/mapr: failed to get ARG_MAX" >&2
	return 1
fi
let "_Msh_mapr_max -= 2048"  # leave room for environment variables
readonly _Msh_mapr_max

mapr() {
	# ___ begin option parser ___
	# Generated with the command: generateoptionparser -o -f 'mapr' -v '_Msh_Mo_' -n 'P' -a 'dnscm'
	unset -v _Msh_Mo_P _Msh_Mo_d _Msh_Mo_n _Msh_Mo_s _Msh_Mo_c _Msh_Mo_m
	forever do
		case ${1-} in
		( -[!-]?* ) # split a set of combined options
			_Msh_Mo__o=${1#-}
			shift
			forever do
				case ${_Msh_Mo__o} in
				( '' )	break ;;
				# if the option requires an argument, split it and break out of loop
				# (it is always the last in a combined set)
				( [dnscm]* )
					_Msh_Mo__a=-${_Msh_Mo__o%"${_Msh_Mo__o#?}"}
					push _Msh_Mo__a
					_Msh_Mo__o=${_Msh_Mo__o#?}
					if not str empty "${_Msh_Mo__o}"; then
						_Msh_Mo__a=${_Msh_Mo__o}
						push _Msh_Mo__a
					fi
					break ;;
				esac
				# split options that do not require arguments (and invalid options) until we run out
				_Msh_Mo__a=-${_Msh_Mo__o%"${_Msh_Mo__o#?}"}
				push _Msh_Mo__a
				_Msh_Mo__o=${_Msh_Mo__o#?}
			done
			while pop _Msh_Mo__a; do
				set -- "${_Msh_Mo__a}" "$@"
			done
			unset -v _Msh_Mo__o _Msh_Mo__a
			continue ;;
		( -[P] )
			eval "_Msh_Mo_${1#-}=''" ;;
		( -[dnscm] )
			let "$# > 1" || die "mapr: $1: option requires argument" || return
			eval "_Msh_Mo_${1#-}=\$2"
			shift ;;
		( -- )	shift; break ;;
		( -* )	die "mapr: invalid option: $1" || return ;;
		( * )	break ;;
		esac
		shift
	done
	# ^^^ end option parser ^^^

	# validate/sanitise option values

	if isset _Msh_Mo_P; then
		if isset _Msh_Mo_d; then
			die "mapr: -d and -P cannot be used together" || return
		fi
		# a null RS (record separator) triggers paragraph mode in awk
		_Msh_Mo_d=''
	elif isset _Msh_Mo_d; then
		if thisshellhas BUG_MULTIBYTE; then
			_Msh_M_dL=$( put "${_Msh_Mo_d}" | {
				PATH=$DEFPATH command wc -m || die "mapr: system error: 'wc' failed"
			} )
		else
			_Msh_M_dL=${#_Msh_Mo_d}
		fi
		if let "${_Msh_M_dL} != 1"; then
			die "mapr: -d: input record separator must be one character" || return
		fi
		unset -v _Msh_M_dL
	else
		_Msh_Mo_d=$CCn
	fi

	if isset _Msh_Mo_n; then
		if not str isint "${_Msh_Mo_n}" || let "_Msh_Mo_n < 0"; then
			die "mapr: -n: invalid number of records: ${_Msh_Mo_n}" || return
		fi
		_Msh_Mo_n=$((_Msh_Mo_n))
	else
		_Msh_Mo_n=0
	fi

	if isset _Msh_Mo_s; then
		if not str isint "${_Msh_Mo_s}" || let "_Msh_Mo_s < 0"; then
			die "mapr: -s: invalid number of records: ${_Msh_Mo_s}" || return
		fi
		_Msh_Mo_s=$((_Msh_Mo_s))
	else
		_Msh_Mo_s=0
	fi

	if isset _Msh_Mo_c; then
		if not str isint "${_Msh_Mo_c}" || let "_Msh_Mo_c < 0"; then
			die "mapr: -c: invalid number of records: ${_Msh_Mo_c}" || return
		fi
		_Msh_Mo_c=$((_Msh_Mo_c))
	else
		_Msh_Mo_c=0
	fi

	if isset _Msh_Mo_m; then
		if not str isint "${_Msh_Mo_m}" || let "_Msh_Mo_m < 0"; then
			die "mapr: -m: invalid number of bytes: ${_Msh_Mo_m}" || return
		fi
		_Msh_Mo_m=$((_Msh_Mo_m))
	else
		_Msh_Mo_m=0
	fi

	let "$# > 0" || die "mapr: callback command expected" || return
	not str begin "$1" _Msh_ || die "mapr: modernish internal namespace not supported for callback" || return

	# --- main loop ---

	thisshellhas BUG_EVALCOBR && _Msh_M_BUG_EVALCOBR=   # provide dummy loop below within 'eval' to make 'break' work

	_Msh_M_NR=1	# remember NR between awk invocations
	while not str begin "${_Msh_M_NR}" "RET"; do
		# Process one batch of input, producing and eval'ing commands until
		# end of file or until a batch limit (quantum or length) is reached.
		# Export LC_ALL=C to make awk length() count bytes, not characters.
		eval "${_Msh_M_BUG_EVALCOBR+forever do }$(
			export _Msh_M_NR _Msh_Mo_d _Msh_Mo_s _Msh_Mo_n _Msh_Mo_c _Msh_Mo_m \
				POSIXLY_CORRECT=y LC_ALL=C "_Msh_ARG_MAX=${_Msh_mapr_max}"  # BUG_NOEXPRO compat
			extern -p awk -f "$MSH_AUX/var/mapr.awk" "$@" || die "mapr: 'awk' failed"
		)${_Msh_M_BUG_EVALCOBR+; break; done}"
	done

	# cleanup; return with appropriate exit status

	eval "unset -v _Msh_Mo_P _Msh_Mo_d _Msh_Mo_n _Msh_Mo_s _Msh_Mo_c _Msh_Mo_m \
			_Msh_M_ifQuantum _Msh_M_checkMax _Msh_M_NR _Msh_M_FIFO _Msh_M_i \
			_Msh_M_BUG_EVALCOBR _Msh_E
		return ${_Msh_M_NR#RET}"
}

# Check a non-zero exit status of the callback command.
_Msh_mapr_ckE() {
	_Msh_E=$?
	case ${_Msh_E} in
	( $SIGPIPESTATUS )
		_Msh_M_NR=RET$SIGPIPESTATUS ;;
	( 255 )	_Msh_M_NR=RET1 ;;
	( * )	shellquoteparams
		die "mapr: callback failed with status ${_Msh_E}: $@" || _Msh_M_NR=RET$? ;;
	esac
	return 1
}

if thisshellhas ROFUNC; then
	readonly -f mapr _Msh_mapr_ckE
fi
