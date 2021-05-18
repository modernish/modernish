#! /module/for/moderni/sh
\command unalias assign 2>/dev/null
#
# var/string/assign: process assignment-arguments.
#
# The 'assign' command takes assignment-arguments like 'export' and 'readonly'
# except it does nothing but assign values to variables. This is useful if you
# want to use a variable name from another variable, which is not possible
# using a regular shell assignment and would require the dreaded 'eval'. The
# 'assign' command uses safe methods with proper input validation.
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

unset -v _Msh_test # BUG_ARITHTYPE compat
if thisshellhas typeset && _Msh_test=no && command typeset -g _Msh_test=ok && str eq "${_Msh_test-}" ok; then
	# We have typeset -g (zsh, bash 4+, mksh R55+, yash).
	assign() {
		case $# in
		( 0 )	die "assign: at least 1 assignment-argument expected" ;;
		esac
		typeset _Msh_V	# local
		for _Msh_V do
			str in "${_Msh_V}" '=' || die "assign: not an assignment-argument: ${_Msh_V}"
			str isvarname "${_Msh_V%%=*}" || die "assign: invalid variable name: ${_Msh_V%%=*}"
		done
		command typeset -g "$@" || die "assign: 'typeset' failed"
	}
elif thisshellhas typeset KSH93FUNC && _Msh_test=no && command typeset _Msh_test=ok && str eq "${_Msh_test-}" ok; then
	# ksh93 uses typeset without -g; this does not make the variable local,
	# as long as it's in a POSIX function defined using the name() syntax.
	assign() {
		case $# in
		( 0 )	die "assign: at least 1 assignment-argument expected" ;;
		esac
		for _Msh_a_V do
			str in "${_Msh_a_V}" '=' || die "assign: not an assignment-argument: ${_Msh_a_V}"
			str isvarname "${_Msh_a_V%%=*}" || die "assign: invalid variable name: ${_Msh_a_V%%=*}"
		done
		unset -v _Msh_a_V
		command typeset "$@" || die "assign: 'typeset' failed"
	}
elif thisshellhas typeset global && _Msh_test=no && command global _Msh_test=ok && str eq "${_Msh_test-}" ok; then
	# mksh <R55 uses a separate 'global' builtin instead of a -g flag for typeset.
	# TODO: remove when support for mksh <R55 stops
	assign() {
		case $# in
		( 0 )	die "assign: at least 1 assignment-argument expected" ;;
		esac
		typeset _Msh_V	# local
		for _Msh_V do
			str in "${_Msh_V}" '=' || die "assign: not an assignment-argument: ${_Msh_V}"
			str isvarname "${_Msh_V%%=*}" || die "assign: invalid variable name: ${_Msh_V%%=*}"
		done
		command global "$@" || die "assign: 'global' failed"
	}
else
	# All other shells have to use 'eval'. We properly validate arguments, so it's safe.
	assign() {
		case $# in
		( 0 )	die "assign: at least 1 assignment-argument expected" ;;
		esac
		for _Msh_a_V do
			str in "${_Msh_a_V}" '=' || die "assign: not an assignment-argument: ${_Msh_a_V}"
			str isvarname "${_Msh_a_V%%=*}" || die "assign: invalid variable name: ${_Msh_a_V%%=*}"
		done
		for _Msh_a_V do
			# It is only safe if we do *not* to expand the value at the eval stage, so escape the expansion.
			command eval "${_Msh_a_V%%=*}=\${_Msh_a_V#*=}" || die "assign: assignment failed"
		done
		unset -v _Msh_a_V
	}
fi 2>/dev/null
unset -v _Msh_test

if thisshellhas ROFUNC; then
	readonly -f assign
fi
