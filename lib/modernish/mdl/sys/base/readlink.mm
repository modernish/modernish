#! /module/for/moderni/sh
\command unalias readlink _Msh_doReadLink 2>/dev/null

# modernish sys/base/readlink
#
# 'readlink', read the target of a symbolic link, is a very useful but
# non-standard command that varies widely across system. Some systems don't
# have it and the options are not the same everywhere. The BSD/Mac OS X
# version is not robust with trailing newlines in link targets. So here
# is a cross-platform consistent 'readlink'.
#
# Additional benefit: this implementation stores the link target in $REPLY,
# including any trailing newlines. This means that
#	readlink "$file"
#	do_stuff "$REPLY"
# is more robust than
#	do_stuff "$(readlink "$file")"
# (Remember that the latter form, using a command substitution, involves
# forking a subshell, so the changes to the REPLY variable are lost.)
#
# Note: if more than one argument is given, the links are stored in REPLY
# separated by newlines, so using more than one argument is not robust
# by default. To deal with this, add '-Q' for shell-quoted output and
# use something like 'eval' to parse the output as proper shell arguments.
#
# Usage:
#	readlink [ -nsfQ ] <file> [ <file> ... ]
#	-n: don't output trailing newline
#	-s: don't output anything (still store in REPLY)
#	-f: canonicalize path and follow all symlinks encountered (all but
#	    the last component must exist)
#	-Q: shell-quote each item of output; separate multiple items with
#	    spaces instead of newlines
#
# Note: the -n option works differently from both BSD and GNU 'readlink'. The
# BSD version removes *all* newlines, which makes the output for multiple
# arguments useless, as there is no separator. The GNU version ignores the
# -n option if there are multiple arguments. The modernish -n option acts
# consistently: it removes the final newline only, so multiple arguments are
# still separated by newlines.
#
# TODO: implement '-e' and '-m' as in GNU readlink
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

# Internal core routine for reading the contents of a symlink.
# Given the absence of a standard readlink command, the only portable way to do this is using
# the output of 'ls -ld', which prints the symlink target after ' -> '. In spite of the widespread
# and mostly justified taboo against parsing 'ls' output, there is a way to make this robust: we
# can use the fact that the standard specifies the ' -> ' separator for all locales[*].
# [*] http://pubs.opengroup.org/onlinepubs/9699919799/utilities/ls.html#tag_20_73_10
_Msh_doReadLink() {
	is sym "$1" || return 1
	_Msh_rL_F=$(PATH=$DEFPATH command ls -ld -- "$1" && put X) \
	|| die "readlink: system command 'ls -ld' failed"
	# Remove single newline added by 'ls' and the X used to stop the cmd subst from stripping all final newlines.
	_Msh_rL_F2=${_Msh_rL_F%"$CCn"X}
	str eq "${_Msh_rL_F2}" "${_Msh_rL_F}" && die "readlink: internal error 1"
	# Remove 'ls' output except for link target. Include filename $1 in search pattern,
	# so this works even if the link filename and/or the link's target contain ' -> '.
	_Msh_rL_F=${_Msh_rL_F2#*" $1 -> "}
	str eq "${_Msh_rL_F}" "${_Msh_rL_F2}" && die "readlink: internal error 2"
	unset -v _Msh_rL_F2
}

readlink() {
	# ___begin option parser___
	# The command used to generate this parser was:
	# generateoptionparser -o -n 'nsfQ' -f 'readlink' -v '_Msh_rL_
	# Then '--help' and the extended usage message were added manually.
	unset -v _Msh_rL_n _Msh_rL_s _Msh_rL_f _Msh_rL_Q
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
		( -[nsfQ] )
			eval "_Msh_rL_${1#-}=''" ;;
		( -- )	shift; break ;;
		( --help )
			putln "modernish $MSH_VERSION sys/base/readlink" \
				"usage: readlink [ -nsfQ ] [ FILE ... ]" \
				"   -n: Don't output trailing newline." \
				"   -s: Don't output anything (still store in REPLY)." \
				"   -f: Canonicalise path and follow all symlinks encountered." \
				"   -Q: Shell-quote each pathname. Separate by spaces."
			return ;;
		( -* )	die "readlink: invalid option: $1" \
				"${CCn}usage:${CCt}readlink [ -nsfQ ] [ FILE ... ]" \
				"${CCn}${CCt}readlink --help" || return ;;
		( * )	break ;;
		esac
	do
		shift
	done
	# ^^^ end option parser ^^^
	_Msh_rL_err=0
	isset _Msh_rL_n || _Msh_rL_n=$CCn
	let "$#" || die "readlink: at least one non-option argument expected" \
				"${CCn}usage:${CCt}readlink [ -nsfQ ] [ FILE ... ]" \
				"${CCn}${CCt}readlink --help" || return

	unset -v REPLY	# BUG_ARITHTYPE compat
	REPLY=''
	for _Msh_rL_F do
		if isset _Msh_rL_f; then
			# Canonicalise: convert to absolute, physical path using modernish 'chdir' in subshell.
			# (Note: readlink -f canonicalises even non-symlink paths. All but the last component must exist.)
			_Msh_rL_F=$(
				: 1>&1	# BUG_CSUBSTDO workaround
				case ${_Msh_rL_F} in
				(?*/*)	chdir -f -- "${_Msh_rL_F%/*}" 2>/dev/null || \exit 0 ;;
				(/*)	chdir / ;;
				esac
				_Msh_rL_F=${_Msh_rL_F##*/}
				while _Msh_doReadLink "${_Msh_rL_F}"; do
					case ${_Msh_rL_F} in
					(?*/*)	chdir -f -- "${_Msh_rL_F%/*}" 2>/dev/null || \exit 0 ;;
					(/*)	chdir / ;;
					esac
					_Msh_rL_F=${_Msh_rL_F##*/}
				done
				case $PWD in
				( / )	put "/${_Msh_rL_F}X" ;;
				( * )	case ${_Msh_rL_F} in
					( '' )	put "${PWD}X" ;;
					( * )	put "$PWD/${_Msh_rL_F}X" ;;
					esac ;;
				esac
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
	eval "unset -v _Msh_rL_n _Msh_rL_s _Msh_rL_f _Msh_rL_Q _Msh_rL_F _Msh_rL_err; return ${_Msh_rL_err}"
}

if thisshellhas ROFUNC; then
	readonly -f readlink _Msh_doReadLink
fi
