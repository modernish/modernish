#! /module/for/moderni/sh
\command unalias readlink _Msh_doReadLink _Msh_doReadLink_canon _Msh_doReadLink_canon_nonexist 2>/dev/null

# modernish sys/base/readlink
#
# 'readlink', read the target of a symbolic link, is a very useful but
# non-standard command that varies widely across system. Some systems don't
# have it and the options are not the same everywhere. So here is a
# cross-platform 'readlink' that integrates into the shell.
#
# Usage:
#	readlink [ -nsefmQ ] <file> [ <file> ... ]
#	-n: don't output trailing newline (but keep separating newlines)
#	-s: don't output anything (still store in REPLY)
#	-e: canonicalise path and follow all symlinks encountered
#	    (all pathname components must exist)
#	-f: like -e, but the last pathname component does not need to exist
#	-m: like -e, but no pathname component needs to exist
#	-Q: shell-quote each item of output; separate multiple items with
#	    spaces instead of newlines
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

# Internal core routine for reading the contents of a symlink.
# Given the absence of a standard readlink command, the only portable way to do this is using
# the output of 'ls -ld', which prints the symlink target after ' -> '. In spite of the widespread
# and mostly justified taboo against parsing 'ls' output, there is a way to make this robust: we
# can use the fact that the standard specifies the ' -> ' separator for all locales[*].
# [*] http://pubs.opengroup.org/onlinepubs/9699919799/utilities/ls.html#tag_20_73_10
_Msh_doReadLink() {
	is sym "$1" || return 1

	# Avoid an infinite loop on encountering a recursive symlink when canonicalising.
	str begin "$1" / && _Msh_rL_F2=$1 || _Msh_rL_F2=$PWD/$1
	str in "/$CC01/${_Msh_rL_seen}/$CC01/" "/$CC01/${_Msh_rL_F2}/$CC01/" && return 1
	_Msh_rL_seen=${_Msh_rL_seen:+$_Msh_rL_seen/$CC01/}${_Msh_rL_F2}

	_Msh_rL_F=$(PATH=$DEFPATH command ls -ld -- "$1" 2>/dev/null && put X) \
	|| die "readlink: system command 'ls -ld' failed"

	# Remove single newline added by 'ls' and the X used to stop the cmd subst from stripping all final newlines.
	_Msh_rL_F2=${_Msh_rL_F%"$CCn"X}
	str eq "${_Msh_rL_F2}" "${_Msh_rL_F}" && die "readlink: internal error 1"

	# Remove 'ls' output except for link target. Include filename $1 in search pattern,
	# so this works even if the link filename and/or the link's target contain ' -> '.
	_Msh_rL_F=${_Msh_rL_F2#*" $1 -> "}
	if str eq "${_Msh_rL_F}" "${_Msh_rL_F2}"; then
		if str end "${_Msh_rL_F}" " $1" && not str in "${_Msh_rL_F%" $1"}" ' -> '; then
			# Symlink without read permission (macOS)
			_Msh_rL_F=$1
			unset -v _Msh_rL_F2
			return 1
		fi
		die "readlink: internal error 2"
	fi
	unset -v _Msh_rL_F2
}

# Main canonicalisation function (-e, -f, -m). Called from a subshell with split & glob disabled.
_Msh_doReadLink_canon() {
	# Compatibility with illogical GNU 'readlink' behaviour: for nonexistent 'foo'
	# or broken symlink 'foo', 'readlink -f foo/' is the same as 'readlink -f foo'.
	case $1 in
	( *[!/]*/ )
		_Msh_tmp=$1
		while str end "${_Msh_tmp}" '/'; do
			_Msh_tmp=${_Msh_tmp%/}
		done
		not is -L present "${_Msh_tmp}" && set -- "${_Msh_tmp}" ;;
	esac

	# If an absolute path was given, change to root directory or (if UNC path) to the UNC share root.
	if str match "$1" '//[!/]*/*[!/]*/*[!/]*'; then
		# UNC //server/share/file: treat //server/share as a whole, as we can't always chdir to //server on Cygwin
		_Msh_D=${1#//[!/]*/*[!/]*/}
		chdir -f -- "${1%/"$_Msh_D"}" 2>/dev/null && set -- "${_Msh_D}" || chdir //
	elif str match "$1" '//[!/]*' || str eq "$1" '//'; then
		# UNC //server/share, //server or //
		chdir -f -- "$1" 2>/dev/null && set -- '' || chdir //
	elif str begin "$1" '/'; then
		# normal absolute path
		chdir /
	fi

	# Canonicalise the path using 'chdir' to convert to physical path.
	# If -m given, emulate traversal of nonexistent paths.
	str in "$1" '/' || set -- "./$1"
	str begin "$1" './' && { str ne "${PWD:-.}" '.' && is -L dir "$PWD" && chdir -f -- "$PWD" || \exit 0; }
	{ str end "$1" '/.' || str end "$1" '/..'; } && set -- "$1/"
	unset -v _Msh_nonexist
	IFS='/'
	for _Msh_D in ${1%/*}; do
		if str empty "${_Msh_D}" || str eq "${_Msh_D}" '.'; then
			continue
		elif isset _Msh_nonexist; then
			_Msh_doReadLink_canon_nonexist "${_Msh_D}"
		elif chdir -f -- "${_Msh_D}" 2>/dev/null; then
			:
		elif str eq "${_Msh_rL_canon}" 'm'; then
			while _Msh_doReadLink "${_Msh_D}"; do
				if str in "${_Msh_rL_F}" '/'; then
					_Msh_doReadLink_canon "${_Msh_rL_F}"
					return
				else
					_Msh_D=${_Msh_rL_F}
				fi
			done
			_Msh_nonexist=
			_Msh_doReadLink_canon_nonexist "${_Msh_D}"
		else
			\exit 0
		fi
	done
	IFS=
	_Msh_rL_F=${1##*/}
}

# Canonicalise one nonexistent pathname component (no slashes, empties or '.'),
# and check if we have re-entered existing space.
_Msh_doReadLink_canon_nonexist() {
	case $1 in
	( .. )	PWD=${PWD%/*}
		case $PWD in
		( *[!/] ) ;;
		( * )	  PWD=$PWD/ ;;
		esac ;;
	( * )	case $PWD in
		( *[!/] ) PWD=$PWD/$1 ;;
		( * )	  PWD=$PWD$1 ;;
		esac ;;
	esac
	if chdir -f -- "$PWD" 2>/dev/null; then
		unset -v _Msh_nonexist
	fi
}

readlink() {
	# ___begin option parser___
	unset -v _Msh_rL_n _Msh_rL_s _Msh_rL_Q _Msh_rL_canon
	while	case ${1-} in
		( -[!-]?* ) # split a set of combined options
			_Msh_rL__o=${1#-}
			shift
			while not str empty "${_Msh_rL__o}"; do
				set -- "-${_Msh_rL__o#"${_Msh_rL__o%?}"}" "$@"	#"
				_Msh_rL__o=${_Msh_rL__o%?}
			done
			unset -v _Msh_rL__o
			continue ;;
		( -[efm] )
			_Msh_rL_canon=${1#-} ;;
		( -[nsQ] )
			eval "_Msh_rL_${1#-}=''" ;;
		( -- )	shift; break ;;
		( --help )
			putln "modernish $MSH_VERSION sys/base/readlink" \
				"usage: readlink [ -nsefmQ ] [ FILE ... ]" \
				"   -n: Don't output trailing newline." \
				"   -s: Don't output anything (still store in REPLY)." \
				"   -e: Canonicalise path and follow all symlinks encountered." \
				"       All pathname components must exist." \
				"   -f: Like -e, but the last component does not need to exist." \
				"   -m: Like -e, but no component needs to exist." \
				"   -Q: Shell-quote each pathname. Separate by spaces."
			return ;;
		( -* )	die "readlink: invalid option: $1" \
				"${CCn}usage:${CCt}readlink [ -nsfQ ] [ FILE ... ]" \
				"${CCn}${CCt}readlink --help" ;;
		( * )	break ;;
		esac
	do
		shift
	done
	# ^^^ end option parser ^^^
	_Msh_rL_err=0
	isset _Msh_rL_n || _Msh_rL_n=$CCn
	let "$#" || die "readlink: at least one non-option argument expected" \
				"${CCn}usage:${CCt}readlink [ -nsefmQ ] [ FILE ... ]" \
				"${CCn}${CCt}readlink --help"

	unset -v REPLY	# BUG_ARITHTYPE compat
	REPLY=''
	for _Msh_rL_F do
		_Msh_rL_seen=
		if isset _Msh_rL_canon; then
			# Canonicalise: convert to absolute, physical path.
			_Msh_rL_F=$(
				set -f 1>&1	# no glob; BUG_CSUBSTDO workaround
				IFS=''		# no split
				_Msh_doReadLink_canon "${_Msh_rL_F}"
				while _Msh_doReadLink "${_Msh_rL_F}"; do
					_Msh_doReadLink_canon "${_Msh_rL_F}"
				done
				case $PWD in
				( *[!/] )
					case ${_Msh_rL_F} in
					( '' )	_Msh_rL_F=$PWD ;;
					( * )	_Msh_rL_F=$PWD/${_Msh_rL_F} ;;
					esac ;;
				( * )	_Msh_rL_F=$PWD${_Msh_rL_F} ;;
				esac
				case ${_Msh_rL_canon} in
				( e )	is -L present "${_Msh_rL_F}" || \exit 0 ;;
				esac
				put "${_Msh_rL_F}X"
			) || die "readlink -f: internal error"
			if str empty "${_Msh_rL_F}"; then
				_Msh_rL_err=1
				continue
			fi
			_Msh_rL_F=${_Msh_rL_F%X}
		else
			# Don't canonicalise.
			_Msh_doReadLink "${_Msh_rL_F}" || {
				_Msh_rL_err=1
				continue
			}
		fi
		if isset _Msh_rL_Q; then
			shellquote -f _Msh_rL_F
			REPLY=${REPLY:+$REPLY }${_Msh_rL_F}
		else
			REPLY=${REPLY:+$REPLY$CCn}${_Msh_rL_F}
		fi
	done
	if not str empty "$REPLY" && not isset _Msh_rL_s; then
		put "${REPLY}${_Msh_rL_n}"
	fi
	eval "unset -v _Msh_rL_n _Msh_rL_s _Msh_rL_Q _Msh_rL_canon _Msh_rL_F _Msh_rL_err _Msh_rL_seen; return ${_Msh_rL_err}"
}

if thisshellhas ROFUNC; then
	readonly -f readlink _Msh_doReadLink _Msh_doReadLink_canon _Msh_doReadLink_canon_nonexist
fi
