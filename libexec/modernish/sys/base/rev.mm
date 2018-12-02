#! /module/for/moderni/sh
unalias rev

# modernish sys/text/rev
# 
# Writes specified files to standard output, reversing the order of
# characters in every line. This utility is provided because, while a binary
# 'rev' is included in most Linux, BSD and Mac OS X-based distributions,
# other Unixes like Solaris and older Mac OS X still don't include it.
#
# Usage: like 'rev' on Linux and BSD, which is like 'cat' except that '-' is
# a filename and does not denote standard input. No options are supported.
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

# Implement 'rev' as a sed script, not awk, because the 'awk' command
# (unlike 'sed') does not take pure filenames as arguments after the script;
# they are interpreted for awk variable assignments and '-' as stdin,
# causing an incompatibility with Linux and BSD 'rev'.

_Msh_rev_sedscript='
		G
		:rev
		s/\(.\)\(\n.*\)/\2\1/
		t rev
		s/.//
	'

case ${LC_ALL:-${LC_CTYPE:-${LANG:-}}} in
( *[Uu][Tt][Ff]8* | *[Uu][Tt][Ff]-8* )
	# If we're in a UTF-8 locale, try to find a sed that can correctly rev UTF-8 strings
	if identic "$(putln 'mĳn δéjà_вю' | PATH=$DEFPATH command sed "${_Msh_rev_sedscript}")" 'юв_àjéδ nĳm'; then
		_Msh_rev_sed=$(PATH=$DEFPATH; command -v sed)
	elif identic "$(putln 'mĳn δéjà_вю' | command gsed "${_Msh_rev_sedscript}")" 'юв_àjéδ nĳm'; then
		_Msh_rev_sed=$(command -v gsed)
	else
		putln "rev: WARNING: cannot find UTF-8 capable sed; rev'ing UTF-8 strings is broken" >&2
		_Msh_rev_sed=$(PATH=$DEFPATH; command -v sed)
	fi ;;
( * )	# In any other locale, just use the system's sed
	_Msh_rev_sed=$(PATH=$DEFPATH; command -v sed) ;;
esac
if not can exec "${_Msh_rev_sed}"; then
	putn "sys/base/rev: Can't find a functioning 'sed'" >&2
	return 1
fi

shellquote _Msh_rev_sed _Msh_rev_sedscript
eval 'rev() {
	'"${_Msh_rev_sed} ${_Msh_rev_sedscript}"' || case $? in
	( "$SIGPIPESTATUS" )
		return "$SIGPIPESTATUS" ;;
	( * )	die "rev: sed failed" ;;
	esac
}'

unset -v _Msh_rev_sed _Msh_rev_sedscript

if thisshellhas ROFUNC; then
	readonly -f rev
fi
