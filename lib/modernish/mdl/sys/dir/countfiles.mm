#! /module/for/moderni/sh
\command unalias countfiles 2>/dev/null

# modernish sys/dir/countfiles
#
# countfiles [ -s ] <directory> [ <globpattern> ... ]:
# Count the number of files in a directory, storing the number in $REPLY
# and (unless -s is given) printing it to standard output.
# If any <globpattern>s are given, only count the files matching them.
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

countfiles() {
	unset -v _Msh_cF_s
	while str begin "${1-}" '-'; do
		case $1 in
		( -s )	_Msh_cF_s=y ;;
		( -- )	shift; break ;;
		( * )	die "countfiles: invalid option: $1" ;;
		esac
		shift
	done
	case $# in
	( 0 )	die "countfiles: at least one non-option argument expected" ;;
	( 1 )	set -- "$1" '.[!.]*' '..?*' '*' ;;
	esac

	if not is -L dir "$1"; then
		die "countfiles: not a directory: $1"
	fi

	REPLY=0

	push IFS -f
	IFS=''
	set +f
	_Msh_cF_dir=$1
	shift
	str in "$*" / && { pop IFS -f; die "countfiles: directories in patterns not supported"; }
	for _Msh_cF_pat do
		set -- "${_Msh_cF_dir}"/${_Msh_cF_pat}
		if is present "$1"; then
			let REPLY+=$#
		fi
	done
	unset -v _Msh_cF_pat _Msh_cF_dir
	pop IFS -f
	isset _Msh_cF_s && unset -v _Msh_cF_s || putln "$REPLY"
}

if thisshellhas ROFUNC; then
	readonly -f countfiles
fi
