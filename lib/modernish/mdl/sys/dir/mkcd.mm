#! /module/for/moderni/sh
\command unalias mkcd 2>/dev/null

# sys/dir/mkcd
#
# mkcd: make one or more directories, then cd into the last-mentioned one.
# All given arguments are passed to mkdir, so usage depends on mkdir.
#
# --- begin license ---
# Copyright (c) 2019 Martijn Dekker <martijn@inlv.org>
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

mkcd() {
	PATH=$DEFPATH command mkdir "$@" || die "mkcd: mkdir failed"
	shift "$(( $# - 1 ))"
	# Bypass "-" and zsh directory stack identifiers by prepending "./", but don't prepend "./"
	# if it is not strictly necessary, as this carries a (small) risk of exceeding PATH_MAX.
	case $1 in
	( */* | [!+-]* | *[!0123456789]* )
		;;
	( * )	set -- "./$1" ;;
	esac
	# When running a script, use -P to resolve symlinks as this is more secure.
	case $- in
	( *i* )	CDPATH='' command cd -- "$1" ;;
	( * )	CDPATH='' command cd -P -- "$1" ;;
	esac || die "mkcd: cd failed"
}

if thisshellhas ROFUNC; then
	readonly -f mkcd
fi
