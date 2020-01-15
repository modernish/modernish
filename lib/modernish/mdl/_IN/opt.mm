#! /module/for/moderni/sh
\command unalias _Msh_optNamCanon _Msh_optNamToLtr _Msh_optNamToVar 2>/dev/null

# _IN/opt
#
# Internal module for shell options handling.
#
# These functions are used by thisshellhas(), push(), pop(), and several var/stack modules.
# They are not part of the public API and should not be relied on in scripts.
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


# Canonicalise a long shell option name according to current shell quirks, leaving the canonical name in
# _Msh_opt. Returns 0 if option exists, 1 if not, 2 if the identifier is invalid and was not canonicalised.
_Msh_optNamCanon() {
	_Msh_opt=$1
	case $1 in
	( "" | *[!"$ASCIIALNUM"_-]* )
		return 2 ;;
	esac
	if thisshellhas QRK_OPTCASE && str match "${_Msh_opt}" '*[A-Z]*'; then
		_Msh_opt=$(unset -f tr	# QRK_EXECFNBI compat
			putln "${_Msh_opt}" | PATH=$DEFPATH LC_ALL=C exec tr A-Z a-z) \
		|| die 'internal error in _Msh_optNamCanon()'
	fi
	if thisshellhas QRK_OPTULINE; then
		while str in "${_Msh_opt}" '_'; do	# remove '_'
			_Msh_opt=${_Msh_opt%%_*}${_Msh_opt#*_}
		done
	fi
	if thisshellhas QRK_OPTDASH; then
		while str in "${_Msh_opt}" '-'; do	# remove '-'
			_Msh_opt=${_Msh_opt%%-*}${_Msh_opt#*-}
		done
	fi
	if thisshellhas QRK_OPTNOPRFX && str begin "${_Msh_opt}" "no"; then
		if thisshellhas QRK_OPTABBR; then
			# This acts like ksh93, not yash, e.g. in that 'not' becomes 't' and
			# matches 'trackall', and is not considered ambiguous with 'notify'.
			str in "${_Msh_allMyLongOpts}" ":${_Msh_opt#no}" && _Msh_opt=${_Msh_opt#no}
		else
			_Msh_opt=${_Msh_opt#no}
		fi
	fi
	# Match the name against the list
	case ${_Msh_allMyLongOpts} in
	( *:"${_Msh_opt}":* )
		# Exact match
		;;
	( *:"${_Msh_opt}"* )
		# Partial match
		thisshellhas QRK_OPTABBR || return 1
		case ${_Msh_allMyLongOpts#*:"$_Msh_opt"} in
		( *:"${_Msh_opt}"* )
			# Ambiguous option abbreviation
			return 1 ;;
		esac
		# Complete the canonical name
		_Msh_opt=${_Msh_opt}${_Msh_allMyLongOpts#*:"$_Msh_opt"}
		_Msh_opt=${_Msh_opt%%:*} ;;
	( * )	# No match
		return 1 ;;
	esac
	if thisshellhas QRK_OPTNOPRFX; then
		# Restore the no- in standard POSIX options
		case ${_Msh_opt} in
		( clobber | exec | glob | log | unset )
			_Msh_opt="no${_Msh_opt}" ;;
		esac
	fi
}

# Convert a long-form option name to short-form option letter, if it exists.
# Leaves the result in _Msh_opt. Returns status 0 if a corresponding short-form option letter exists.
# The option name MUST be canonicalised first.
unset -v _Msh_optLtrCache	# for caching results that require forking a subshell
_Msh_optNamToLtr() {
	case $1 in
	( nolog )	thisshellhas BUG_OPTNOLOG && unset -v _Msh_opt && return 1 ;;
	esac
	case $1 in
	# hard-code option letters guaranteed by POSIX, plus 'i'
	( interactive )	_Msh_opt=i ;;
	( allexport )	_Msh_opt=a ;;
	( errexit )	_Msh_opt=e ;;
	( noclobber )	_Msh_opt=C ;;
	( noglob )	_Msh_opt=f ;;
	( noexec )	_Msh_opt=n ;;
	( nounset )	_Msh_opt=u ;;
	( verbose )	_Msh_opt=v ;;
	( xtrace )	_Msh_opt=x ;;
	# shell-specific option
	( * )	case ${_Msh_optLtrCache-}: in
		( *:"$1"=?:* )
			_Msh_opt=${_Msh_optLtrCache#*:"$1"=}
			_Msh_opt=${_Msh_opt%%:*} ;;
		( *:!"$1":* )
			unset -v _Msh_opt
			return 1 ;;
		( * )	# figure out if there is a letter for that long-form option
			_Msh_opt=$(
				: 1>&1			# BUG_CSUBSTDO workaround
				PATH=$DEFPATH
				case $1 in
				( restricted )
					set -o restricted && command echo 'r'
					\exit ;;
				( shoptionletters )
					# this zsh option affects "$-" so test below would fail
					\exit 1 ;;
				esac
				set -o "$1" 2>/dev/null	# exits subshell with status > 0 if option does not exist
				_Msh_o1=$-
				set +o "$1" 2>/dev/null
				_Msh_o2=$-
				case $(( ${#_Msh_o1} - ${#_Msh_o2} )) in
				( 0 )	# option does not have a letter
					\exit 1 ;;
				( 1 )	;;
				( -1 )	# the long option has an inverse effect to the letter option: swap values
					_Msh_o=${_Msh_o1}
					_Msh_o1=${_Msh_o2}
					_Msh_o2=${_Msh_o} ;;
				( * )	die "internal error 1 in _Msh_optNamToLtr()" ;;
				esac
				# for each char in ${_Msh_o1}, check if it occurs in ${_Msh_o2};
				# if it does NOT occur, we have found our letter
				while ! str empty "${_Msh_o1}"; do
					_Msh_o=${_Msh_o1%${_Msh_o1#?}}	# get first letter
					if ! str in "${_Msh_o2}" "${_Msh_o}"; then
						! str match "${_Msh_o}" "*[!$SHELLSAFECHARS]*" && put "${_Msh_o}"
						\exit
					fi
					_Msh_o1=${_Msh_o1#?}
				done
				die "internal error 2 in _Msh_optNamToLtr()"
			) || {
				_Msh_optLtrCache=${_Msh_optLtrCache-}:!$1
				unset -v _Msh_opt
				return 1
			}
			_Msh_optLtrCache=${_Msh_optLtrCache-}:$1=${_Msh_opt} ;;
		esac
	esac
}

# Validate and convert a long-form option name to its corresponding internal stack variable.
# Usage: _Msh_optNamToVar <optname> <varname> || die ...
_Msh_optNamToVar() {
	_Msh_optNamCanon "$1" || let "$? < 2" || { unset -v _Msh_opt; return 2; }
	_Msh_V=${_Msh_opt}
	if _Msh_optNamToLtr "${_Msh_V}"; then
		eval "$2=_Msh_ShellOptLtr_\${_Msh_opt}"
	else
		while str in "${_Msh_V}" '-'; do	# change any '-' to '_' in variable name
			_Msh_V=${_Msh_V%%-*}_${_Msh_V#*-}
		done
		eval "$2=_Msh_ShellOpt_\${_Msh_V}"
	fi
	unset -v _Msh_opt _Msh_V
}

# -------------------
# --- Module init ---

# Initialise a list of all the shell's canonical long-form option names.
# These are extracted from 'set -o' output. Format unspecified by POSIX, but parseable in practice.
unset -v _Msh_allMyLongOpts
thisshellhas QRK_OPTNOPRFX  # cache this result
_Msh_allMyLongOpts=$(
	: 1>&1	# BUG_CSUBSTDO compat
	IFS=$WHITESPACE; set -fu
	set -- $(set -o)
	# Skip 'set -o' header line(s), if any
	while let "$# >= 2" && str ne "$2" 'on' && str ne "$2" 'off'; do
		shift
	done
	let "$# > 0 && $# % 2 == 0" || exit 1 'internal error in _IN/opt.mm'
	# Remove all the on/off fields and (if QRK_OPTNOPRFX) any 'no' prefixes
	_Msh_even=0
	for _Msh_opt do
		if let "(_Msh_even = !_Msh_even) == 1"; then
			if thisshellhas QRK_OPTNOPRFX \
			&& str begin "${_Msh_opt}" 'no' \
			&& (set -o "${_Msh_opt}" +o "${_Msh_opt#no}") 2>/dev/null; then
				_Msh_opt=${_Msh_opt#no}
			fi
			set -- "$@" "${_Msh_opt}"
		fi
		shift
	done
	# Output a colon-separated list, adding initial and final colons
	IFS=':'; putln ":$*:"
) || return 1
readonly _Msh_allMyLongOpts

if thisshellhas ROFUNC; then
	readonly -f _Msh_optNamCanon _Msh_optNamToLtr _Msh_optNamToVar
fi
