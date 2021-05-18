#! /module/for/moderni/sh
\command unalias _Msh_arg2sig _Msh_arg2sig_sanitise 2>/dev/null

# _IN/sig
#
# Internal module for signal handling.
#
# These functions are used by thisshellhas() and var/stack/trap.
# They are not part of the public API and should not be relied on in scripts.
#
# --- begin license ---
# Copyright (c) 2020 Martijn Dekker <martijn@inlv.org>
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


# Convert an argument in either ${_Msh_sig} or the first argument to a signal name minus the SIG
# prefix, check it for validity, sanitise it, and leave the result in ${_Msh_sig}. The
# corresponding variable name component is left in ${_Msh_sigv}.
# Returns unsuccessfully if the argument does not correspond to a valid signal.
_Msh_psigCache=
_Msh_arg2sig() {
	unset -v _Msh_sigv
	case ${1:+n} in
	( n )	_Msh_sig=$1 ;;
	esac
	case ${_Msh_sig} in
	( 0 )	_Msh_sig=EXIT; _Msh_sigv=EXIT ;;
	( *[!0123456789]* )
		# Signal name: sanitise and validate
		_Msh_arg2sig_sanitise || return 1
		case ${_Msh_sig} in
		( DIE ) use -q var/stack/trap || return 1
			if isset -i && ! insubshell; then	# on an interactive shell,
				_Msh_sig=INT			# ... alias DIE to INT.
			else
				_Msh_sigv=DIE
				return
			fi ;;
		( EXIT )_Msh_sigv=EXIT
			return ;;
		( ERR )	if thisshellhas TRAPZERR; then
				_Msh_sigv=ZERR
				return
			fi ;;
		esac
		# Check the 'kill -l' cache to see if it's known
		case ${_Msh_sigCache} in
		( *\|${_Msh_sig}${CCn}* )
			# use signal number as varname component
			_Msh_sigv=${_Msh_sigCache%\|${_Msh_sig}${CCn}*}
			_Msh_sigv=${_Msh_sigv##*${CCn}} ;;
		( * )	# check for shell-specific numberless pseudosignal
			case ${_Msh_sig} in
			( *[!${ASCIIALNUM}_]* )
				return 1 ;;  # must be valid varname component
			esac
			# testing for a pseudosig requires forking a subshell, so cache results
			case "|${_Msh_psigCache}|" in
			( *"|${_Msh_sig}|"* )
				_Msh_sigv=${_Msh_sig} ;;
			( *"|!${_Msh_sig}|"* )
				return 1 ;;
			( * )	if (command trap - "${_Msh_sig}") 2>/dev/null; then
					_Msh_sigv=${_Msh_sig}
					_Msh_psigCache=${_Msh_psigCache}${_Msh_psigCache:+\|}${_Msh_sig}
				else
					_Msh_psigCache=${_Msh_psigCache}${_Msh_psigCache:+\|}!${_Msh_sig}
					return 1
				fi ;;
			esac ;;
		esac ;;
	( * )	# Signal number: retrieve a 'kill -l' name from the cache
		case ${_Msh_sigCache} in
		( *${CCn}$((_Msh_sig % 128))\|[!${CCn}]* )
			_Msh_sigv=$((_Msh_sig % 128))
			_Msh_sig=${_Msh_sigCache#*${CCn}${_Msh_sigv}\|}
			_Msh_sig=${_Msh_sig%%${CCn}*} ;;
		( * )	return 1 ;;
		esac ;;
	esac
}
# Sanitise/canonicalise the signal name in _Msh_sig. Return unsuccessfully if it's not syntactically valid.
_Msh_arg2sig_sanitise() {
	case ${_Msh_sig} in
	( '' | *[!"$SHELLSAFECHARS"]* )
		return 1 ;;
	( [Ss][Ii][Gg][Nn][Aa][Ll][123456789]* )
		# DragonflyBSD's SignalNN names are unusable, though the signals exist; change back to number
		_Msh_sig=${_Msh_sig#[Ss][Ii][Gg][Nn][Aa][Ll]} ;;
	( *[abcdefghijklmnopqrstuvwxyz]* )
		_Msh_sig=$(unset -f tr	# QRK_EXECFNBI compat
			putln "${_Msh_sig}" | PATH=$DEFPATH LC_ALL=C exec tr a-z A-Z) \
			|| die "trap stack: system error: 'tr' failed" ;;
	( *[!0123456789]* )
		;;
	( * )	# It's a signal number, not a name
		return 1 ;;
	esac
	_Msh_sig=${_Msh_sig#SIG}
}

# -------------------
# --- Module init ---

# Since 'kill -l' is not reliably portable, initialise a cache of sanitised 'kill -l' results.
_Msh_sigCache=
push IFS -f _Msh_sig _Msh_num
IFS=\|; set -f  # split the cmd. subst. below on '|' without globbing
for _Msh_sig in $(
	: 1>&1	# BUG_CSUBSTDO workaround
	_Msh_i=0 PATH=$DEFPATH
	while let "(_Msh_i+=1)<128"; do
		command kill -l "${_Msh_i}" && put "${_Msh_i}|"
	done 2>/dev/null)
do
	_Msh_num=${_Msh_sig##*$CCn}
	_Msh_sig=${_Msh_sig%$CCn*}
	_Msh_arg2sig_sanitise || continue  # Sanitise even 'kill -l' output; it's not always reliable
	_Msh_sigCache=${_Msh_sigCache:-${CCn}}${_Msh_num}\|${_Msh_sig}${CCn}
done
pop IFS -f _Msh_sig _Msh_num
readonly _Msh_sigCache


if thisshellhas ROFUNC; then
	readonly -f _Msh_arg2sig _Msh_arg2sig_sanitise
fi
