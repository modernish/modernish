#! /module/for/moderni/sh
\command unalias assign 2>/dev/null
#
# var/assign: process assignment-arguments.
#
# The 'assign' command takes assignment-arguments like 'export' and 'readonly'
# except it does nothing but assign values to variables. This is useful if you
# want to use a variable name from another variable, which is not possible
# using a regular shell assignment and would require the dreaded 'eval'. The
# 'assign' command uses safe methods with proper input validation.
#
# The '-r' (reference) option causes the part to the right of the '=' to be
# taken as a second variable name, and its value is assigned to the first
# variable instead. '+r' turns this option back off.
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

assign() {
	case $# in
	( 0 )	die "assign: no arguments" ;;
	esac
	_Msh_a_r=	# BUG_ISSETLOOP compat: use value, not set/unset
	for _Msh_a_V do
		case ${_Msh_a_V} in
		( *=* )	;;
		( -r )	_Msh_a_r=r; continue ;;
		( +r )	_Msh_a_r=; continue ;;
		( [+-]* )
			die "assign: invalid option: ${_Msh_a_V}" ;;
		( * )	die "assign: not an assignment-argument: ${_Msh_a_V}" ;;
		esac
		_Msh_a_W=${_Msh_a_V#*=}
		_Msh_a_V=${_Msh_a_V%%=*}
		case ${_Msh_a_V} in
		( [0123456789]* | *[!"$ASCIIALNUM"_]* )
			die "assign: invalid variable name: ${_Msh_a_V}" ;;
		esac
		case ${_Msh_a_r} in
		( r )	case ${_Msh_a_W} in
			( [0123456789]* | *[!"$ASCIIALNUM"_]* )
				die "assign: invalid reference variable name: ${_Msh_a_W}" ;;
			esac
			command eval "${_Msh_a_V}=\${${_Msh_a_W}}" ;;
		( * )	command eval "${_Msh_a_V}=\${_Msh_a_W}" ;;
		esac || die "assign: assignment failed"
	done
	unset -v _Msh_a_V _Msh_a_W _Msh_a_r
}

if thisshellhas ROFUNC; then
	readonly -f assign
fi
