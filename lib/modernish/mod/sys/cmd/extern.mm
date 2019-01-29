#! /module/for/moderni/sh
\command unalias extern 2>/dev/null

# sys/cmd/extern
#
# extern: Run an external command without having to know its exact location,
# even if a built-in command, alias or shell function by that name exists.
# Usage: extern [ -p ] <command> [ <argument> ... ]
#	 extern -v [ -p ] <command> [ <command> ... ]
#	 -p: use system default PATH instead of current PATH, akin to
#	     'command -p' but never uses builtins. Also, 'command -p' is broken
#	     on many shells, but 'extern -p' is reliable as it uses $DEFPATH.
#	 -v: show pathnames of the <command>(s).
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
	unset -v _Msh_v _Msh_p
	while	case ${1-} in
		( -p )	_Msh_p=$DEFPATH ;;
		( -v )	_Msh_v='' ;;
		( -pv | -vp ) _Msh_p=$DEFPATH; _Msh_v='' ;;
		( -- )	shift; break ;;
		( -* )	die "extern: invalid option: $1" || return ;;
		( * )	break ;;
		esac
	do
		shift
	done
	case $# in
	( 0 )	die "extern: command expected" || \exit ;;
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
			( * )	for _Msh_d in ${_Msh_p-$PATH}; do
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
	( * )	for _Msh_d in ${_Msh_p-$PATH}; do
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
