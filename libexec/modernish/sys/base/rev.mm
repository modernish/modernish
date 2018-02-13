#! /module/for/moderni/sh

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
# Copyright (c) 2017 Martijn Dekker <martijn@inlv.org>, Groningen, Netherlands
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
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
