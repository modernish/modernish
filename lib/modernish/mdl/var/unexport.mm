#! /module/for/moderni/sh
\command unalias unexport 2>/dev/null
#
# unexport: the opposite of export.
#
# Clear the 'export' bit of a variable, conserving its value, or assign
# variables without the export bit even if 'set -a' (allexport) is active.
# This allows an "export all variables, except these" way of working. Unlike
# 'export', 'unexport' does not (and cannot) work for read-only variables.
#
# Usage: like 'export'. (However, unlike 'export' in some shells, there
# is no protection against field splitting or pathname expansion! But
# with 'export' you can't rely on that anyway if you work cross-platform.
# So appropriate shell-quoting is necessary if you pass an assignment.)
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

unset -v _Msh_test # BUG_ARITHTYPE compat
if thisshellhas typeset && _Msh_test=no && command typeset --global --unexport _Msh_test=ok && str eq "${_Msh_test}" ok; then
	# yash has 'typeset --unexport'.
	# (Just to be sure, let's not use the short option equivalent 'typeset -X'
	# as it has a very different meaning on recent versions of ksh93!)
	# Still do validation, because yash's 'typeset' silently ignores crazy stuff.
	unexport() {
		case $# in
		( 0 )	die "unexport: need at least 1 argument, got $#" ;;
		esac
		typeset _Msh_V	# local
		for _Msh_V do
			str isvarname "${_Msh_V%%=*}" || die "unexport: invalid variable name: ${_Msh_V%%=*}"
		done
		command typeset --global --unexport "$@" || die "unexport: 'typeset' failed"
	}
elif thisshellhas typeset KSH93FUNC && _Msh_test=no && command typeset +x _Msh_test=ok && str eq "${_Msh_test}" ok; then
	# ksh93 uses typeset without -g; this does not make the variable local,
	# as long as it's in a POSIX function defined using the name() syntax.
	unexport() {
		case $# in
		( 0 )	die "unexport: need at least 1 argument, got $#" ;;
		esac
		for _Msh_nE_V do
			str isvarname "${_Msh_nE_V%%=*}" || die "unexport: invalid variable name: ${_Msh_nE_V%%=*}"
		done
		unset -v _Msh_nE_V
		command typeset +x "$@" || die "unexport: 'typeset' failed"
	}
elif thisshellhas typeset global && _Msh_test=no && command global +x _Msh_test=ok && str eq "${_Msh_test}" ok; then
	# mksh uses a separate 'global' builtin instead of a -g flag for typeset;
	# this is equivalent to 'typeset -g' on zsh and bash 4.
        # TODO: remove when support for mksh <R55 stops
	unexport() {
		case $# in
		( 0 )	die "unexport: need at least 1 argument, got $#" ;;
		esac
		typeset _Msh_V	# local
		for _Msh_V do
			str isvarname "${_Msh_V%%=*}" || die "unexport: invalid variable name: ${_Msh_V%%=*}"
		done
		command global +x "$@" || die "unexport: 'global' failed"
	}
elif thisshellhas typeset && _Msh_test=no && command typeset -g +x _Msh_test=ok && str eq "${_Msh_test}" ok; then
	# zsh and bash 4 also have 'typeset +x', but need the -g flag to
	# keep the variable from becoming local.
	unexport() {
		case $# in
		( 0 )	die "unexport: need at least 1 argument, got $#" ;;
		esac
		typeset _Msh_V	# local
		for _Msh_V do
			str isvarname "${_Msh_V%%=*}" || die "unexport: invalid variable name: ${_Msh_V%%=*}"
		done
		for _Msh_V do
			if isset "${_Msh_V%%=*}" || ! str eq "${_Msh_V%%=*}" "${_Msh_V}"; then
				command typeset -g +x "${_Msh_V}" || die "unexport: 'typeset' failed"
			else	# on zsh, 'typeset' will set the variable, so to remove export flag use 'unset' instead
				unset -v "${_Msh_V}"
			fi
		done
	}
else
	# All other shells have to use trickery: make sure 'set -a' is off,
	# then unset the variable, then assign or restore its value, then
	# restore the previous status of 'set -a'.
	unexport() {
		case $# in
		( 0 )	die "unexport: need at least 1 argument, got $#" ;;
		esac
		for _Msh_nE_V do
			str isvarname "${_Msh_nE_V%%=*}" || die "unexport: invalid variable name: ${_Msh_nE_V%%=*}"
		done
		case $- in
		( *a* ) _Msh_nE_a=y; set +a ;;
		( * )   _Msh_nE_a='' ;;
		esac
		for _Msh_nE_V do
			case ${_Msh_nE_V} in
			( *=* ) unset -v "${_Msh_nE_V%%=*}"
				command eval "${_Msh_nE_V%%=*}=\${_Msh_nE_V#*=}" ;;
			( * )   if isset "${_Msh_nE_V}"; then
					command eval "_Msh_nE_val=\${${_Msh_nE_V}}" &&
					unset -v "${_Msh_nE_V}" &&
					command eval "${_Msh_nE_V}=\${_Msh_nE_val}"
				else
					command eval "${_Msh_nE_V}=" &&  # BUG_UNSETUNXP workaround
					unset -v "${_Msh_nE_V}"
				fi || die "unexport: assignment failed" ;;
			esac
		done
		case ${_Msh_nE_a} in
		( y )   set -a ;;
		esac
		unset -v _Msh_nE_V _Msh_nE_val _Msh_nE_a
	}
fi 2>/dev/null
unset -v _Msh_test

if thisshellhas ROFUNC; then
	readonly -f unexport
fi
