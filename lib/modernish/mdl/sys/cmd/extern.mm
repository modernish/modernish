#! /module/for/moderni/sh
\command unalias extern 2>/dev/null

# sys/cmd/extern
#
# extern: Run an external command without having to know its exact location,
# even if a built-in command, alias or shell function by that name exists.
#
# Usage: extern [ -p ] [ -u <var> ... ] [ <var>=<val> ... ]  <command> [ <argument> ... ]
#	 extern -v [ -p ] <command> [ <command> ... ]
#	 -p: use system default PATH instead of current PATH, akin to
#	     'command -p' but never uses builtins. Also, 'command -p' is broken
#	     on many shells, but 'extern -p' is reliable as it uses $DEFPATH and
#	     exports it (so e.g. 'extern -p sudo cp ...' works as expected).
#	 -v: show pathnames of the <command>(s).
#	 -u: unset (override export of) named variable.
#	 assignment-arguments: export those variables/values to the <command>.
#	     To be used instead of preceding assignments, as this is a function!
#
# Note that this is a subshell function.
#
# --- begin license ---
# Copyright (c) 2019 Martijn Dekker <martijn@inlv.org>, Groningen, Netherlands
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

extern() (
	IFS=':'; set -f -u +a	# safe-ish mode, split on $PATH separator
	unset -v _Msh_v
	while	case ${1-} in
		( -[!-]?* ) # split a set of combined options
			_Msh__o=$1
			shift
			while _Msh__o=${_Msh__o#?} && not str empty "${_Msh__o}"; do
				_Msh__a=-${_Msh__o%"${_Msh__o#?}"} # "
				push _Msh__a
				case ${_Msh__o} in
				( [u]* ) # split optarg
					_Msh__a=${_Msh__o#?}
					not str empty "${_Msh__a}" && push _Msh__a && break ;;
				esac
			done
			while pop _Msh__a; do
				set -- "${_Msh__a}" "$@"
			done
			unset -v _Msh__o _Msh__a
			continue ;;
		( -p )	command export "PATH=$DEFPATH" || die "extern -p: internal error" ;;
		( -v )	_Msh_v='' ;;
		( -u )	let "$# > 1" || die "extern: -u: option requires argument"
			str isvarname "$2" && not str begin "$2" _Msh_ || die "extern: -u: invalid variable name: $2"
			command unset -v "$2" || die "extern: -u: read-only: $2"
			shift ;;
		( -- )	shift; break ;;
		( -* )	die "extern: invalid option: $1" ;;
		( *=* )	_Msh_var=${1%%=*}
			str isvarname "${_Msh_var}" && not str begin "${_Msh_var}" _Msh_ \
			|| die "extern: invalid variable name: ${_Msh_var}"
			command unset -v "${_Msh_var}" || die "extern: -u: read-only: ${_Msh_var}"
			command export "$1" || die "extern: internal error" ;;
		( * )	break ;;
		esac
	do
		shift
	done
	case $# in
	( 0 )	die "extern: command expected" ;;
	esac
	case ${_Msh_v+s} in
	( s )	# -v: check and show command(s)
		_Msh_e=0
		for _Msh_c do
			case ${_Msh_c} in
			( */* )	if can exec "${_Msh_c}"; then
					putln "${_Msh_c}"
					continue
				fi ;;
			( * )	for _Msh_d in $PATH; do
					str empty "${_Msh_d}" && continue
					if can exec "${_Msh_d}/${_Msh_c}"; then
						putln "${_Msh_d}/${_Msh_c}"
						continue 2
					fi
				done ;;
			esac
			_Msh_e=1
		done
		\exit ${_Msh_e} ;;
	esac
	# not -v: run command
	case $1 in
	( */* )	can exec "$1" && exec "$@"
		is -L present "$1" && _Msh_v=$1 ;;
	( * )	for _Msh_d in $PATH; do
			str empty "${_Msh_d}" && continue
			can exec "${_Msh_d}/$1" && exec "${_Msh_d}/$@"
			is -L present "${_Msh_d}/$1" && _Msh_v=${_Msh_d}/$1
		done ;;
	esac
	if isset _Msh_v; then
		putln "${ME##*/}: extern: cannot execute: ${_Msh_v}" 1>&2
		\exit 126
	else
		putln "${ME##*/}: extern: command not found: $1" 1>&2
		\exit 127
	fi
)

# -----------

if thisshellhas ROFUNC; then
	readonly -f extern
fi
