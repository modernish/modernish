#! /helper/script/for/moderni/sh

# This is a helper script called by a translated '-path' primary of 'LOOP
# find' in compatibility mode, if the 'find' utility used has no '-path'
# primary (e.g. on Solaris <= 11.3). It is never used if a fully POSIX
# compliant 'find' utility is found.
#
# All this script does is match a glob pattern $2 against a string $1,
# so it is effectively an external version of modernish 'str match'.
#
# --- begin license ---
# Copyright (c) 2020 Martijn Dekker <martijn@inlv.org>, Groningen, Netherlands
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

case ${ZSH_VERSION+z} in
( z )	# before installation, this may not be called via a 'sh' symlink
	emulate sh ;;
esac

case $# in
( 2 )	;;
( * )	echo "die 'LOOP find: internal error'" >&8
	exit 128 ;;
esac

# Newline character.
CCn='
'

# Match the found file's path ($1) against the glob pattern ($2).
case $2 in
(*\\*)	# Many shells cannot reliably pass backslash-escaped characters from a
	# parameter. Parse patterns containing backslashes as string literals,
	# which requires making the pattern string safe for 'eval'.
	Q=
	P=$2
	while :; do
		case $P in
		( "" )	break ;;
		# Handle newline specially with a ref to $CCn.
		($CCn*)	Q=$Q\${CCn}
			P=${P#?} ;;
		# Handle backslash-escaped newline specially with a ref to $CCn.
		(\\$CCn*)Q=$Q\${CCn}
			P=${P#??} ;;
		# Leave other backslash-escaped characters alone.
		(\\?*)	Q=$Q${P%"${P#??}"}	# "
			P=${P#??} ;;
		# Leave unescaped glob characters and shell-safe characters alone.
		([][?*]* | [0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz%+,./:=@_^!-]*)
			Q=$Q${P%"${P#?}"}	# "
			P=${P#?} ;;
		# Backslash-escape everything else.
		( * )	Q=$Q\\${P%"${P#?}"}	# "
			P=${P#?} ;;
		esac
	done
	eval "case \$1 in
	( $Q )	;;
	( * )	exit 1 ;;
	esac" ;;
( * )	# No backslashes = no need for special handling.
	case $1 in
	( $2 )	;;
	( * )	exit 1 ;;
	esac ;;
esac
