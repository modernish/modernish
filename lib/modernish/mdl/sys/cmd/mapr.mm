#! /module/for/moderni/sh
\command unalias mapr _Msh_mapr_ckE 2>/dev/null

# sys/cmd/mapr
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
#		shell function or any other kind of command.
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
use sys/cmd/procsubst

# determine max length in bytes of arguments we can pass
_Msh_mapr_max=$(extern -p getconf ARG_MAX 2>/dev/null || putln 262144)
if not str isint "${_Msh_mapr_max}" || let "_Msh_mapr_max < 4096"; then
	putln "sys/cmd/mapr: failed to get ARG_MAX" >&2
	return 1
fi
let "_Msh_mapr_max -= (_Msh_mapr_max/8 > 2048 ? _Msh_mapr_max/8 : 2048)"  # leave room for environment variables
readonly _Msh_mapr_max

mapr() {
	# ___ begin option parser ___
	# Generated with the command: generateoptionparser -o -f 'mapr' -v '_Msh_Mo_' -n 'P' -a 'dnscm'
	unset -v _Msh_Mo_P _Msh_Mo_d _Msh_Mo_n _Msh_Mo_s _Msh_Mo_c _Msh_Mo_m
	while	case ${1-} in
		( -[!-]?* ) # split a set of combined options
			_Msh_Mo__o=$1
			shift
			while _Msh_Mo__o=${_Msh_Mo__o#?} && not str empty "${_Msh_Mo__o}"; do
				_Msh_Mo__a=-${_Msh_Mo__o%"${_Msh_Mo__o#?}"} # "
				push _Msh_Mo__a
				case ${_Msh_Mo__o} in
				( [dnscm]* ) # split optarg
					_Msh_Mo__a=${_Msh_Mo__o#?}
					not str empty "${_Msh_Mo__a}" && push _Msh_Mo__a && break ;;
				esac
			done
			while pop _Msh_Mo__a; do
				set -- "${_Msh_Mo__a}" "$@"
			done
			unset -v _Msh_Mo__o _Msh_Mo__a
			continue ;;
		( -[P] )
			eval "_Msh_Mo_${1#-}=''" ;;
		( -[dnscm] )
			let "$# > 1" || die "mapr: $1: option requires argument"
			eval "_Msh_Mo_${1#-}=\$2"
			shift ;;
		( -- )	shift; break ;;
		( -* )	die "mapr: invalid option: $1" ;;
		( * )	break ;;
		esac
	do
		shift
	done
	# ^^^ end option parser ^^^

	# validate/sanitise option values

	if isset _Msh_Mo_P; then
		if isset _Msh_Mo_d; then
			die "mapr: -d and -P cannot be used together"
		fi
		# a null RS (record separator) triggers paragraph mode in awk
		_Msh_Mo_d=''
	elif isset _Msh_Mo_d; then
		if thisshellhas WRN_MULTIBYTE; then
			_Msh_M_dL=$( put "${_Msh_Mo_d}" | {
				PATH=$DEFPATH command wc -m || die "mapr: system error: 'wc' failed"
			} )
		else
			_Msh_M_dL=${#_Msh_Mo_d}
		fi
		if let "${_Msh_M_dL} != 1"; then
			die "mapr: -d: input record separator must be one character"
		fi
		unset -v _Msh_M_dL
	else
		_Msh_Mo_d=$CCn
	fi

	if isset _Msh_Mo_n; then
		if not str isint "${_Msh_Mo_n}" || let "_Msh_Mo_n < 0"; then
			die "mapr: -n: invalid number of records: ${_Msh_Mo_n}"
		fi
		_Msh_Mo_n=$((_Msh_Mo_n))
	else
		_Msh_Mo_n=0
	fi

	if isset _Msh_Mo_s; then
		if not str isint "${_Msh_Mo_s}" || let "_Msh_Mo_s < 0"; then
			die "mapr: -s: invalid number of records: ${_Msh_Mo_s}"
		fi
		_Msh_Mo_s=$((_Msh_Mo_s))
	else
		_Msh_Mo_s=0
	fi

	if isset _Msh_Mo_c; then
		if not str isint "${_Msh_Mo_c}" || let "_Msh_Mo_c < 0"; then
			die "mapr: -c: invalid number of records: ${_Msh_Mo_c}"
		fi
		_Msh_Mo_c=$((_Msh_Mo_c))
	else
		_Msh_Mo_c=0
	fi

	if isset _Msh_Mo_m; then
		if not str isint "${_Msh_Mo_m}" || let "_Msh_Mo_m < 0"; then
			die "mapr: -m: invalid number of bytes: ${_Msh_Mo_m}"
		fi
		_Msh_Mo_m=$((_Msh_Mo_m))
	else
		_Msh_Mo_m=0
	fi

	let "$# > 0" || die "mapr: callback command expected"
	not str begin "$1" _Msh_ || die "mapr: modernish internal namespace not supported for callback"

	# --- main loop ---

	unset -v _Msh_M_status
	while IFS= read -r _Msh_M_cmd <&8; do
		while str end "${_Msh_M_cmd}" '\'; do
			# line continuation
			IFS= read -r _Msh_M_cmd2 <&8 || die "mapr: internal error: line continuation failure"
			_Msh_M_cmd=${_Msh_M_cmd}${CCn}${_Msh_M_cmd2}
			unset -v _Msh_M_cmd2
		done
		eval "${_Msh_M_cmd}" 8<&- || break
	done 8<$(% _Msh_mapr_doAwk "$@" 8<&0)
#					^^^^ save stdin for _Msh_mapr_doAwk() bg job
#	     ^^^^^ connect bg job to FD 8 using sys/cmd/procsubst

	# cleanup; return with appropriate exit status
	isset _Msh_M_status || die "mapr: internal error: no exit status"
	eval "unset -v _Msh_Mo_P _Msh_Mo_d _Msh_Mo_n _Msh_Mo_s _Msh_Mo_c _Msh_Mo_m \
			_Msh_M_ifQuantum _Msh_M_checkMax _Msh_M_status _Msh_M_FIFO _Msh_M_i _Msh_M_cmd
		return ${_Msh_M_status}"
}

# Helper function for running awk in the background using process substitution
_Msh_mapr_doAwk() {
	# Export LC_ALL=C to make awk length() count bytes, not characters.
	export _Msh_Mo_d _Msh_Mo_s _Msh_Mo_n _Msh_Mo_c _Msh_Mo_m \
		POSIXLY_CORRECT=y LC_ALL=C "_Msh_ARG_MAX=${_Msh_mapr_max}"  # BUG_NOEXPRO compat
	extern -p awk -f "$MSH_AUX/sys/cmd/mapr.awk" "$@" <&8 || let "$? < 126 || $? == SIGPIPESTATUS" || die "mapr: 'awk' failed"
}

# Check a non-zero exit status of the callback command.
_Msh_mapr_ckE() {
	_Msh_M_status=$?
	case ${_Msh_M_status} in
	( ? | ?? | 1[01]? | 12[012345] )
		;;
	( "$SIGPIPESTATUS" | 255 )
		return 1 ;;
	( * )	shellquoteparams
		thisshellhas --sig=${_Msh_M_status} && die "mapr: callback killed by SIG$REPLY: $@"
		die "mapr: callback failed with status ${_Msh_M_status}: $@" ;;
	esac
}

if thisshellhas ROFUNC; then
	readonly -f mapr _Msh_mapr_ckE
fi
