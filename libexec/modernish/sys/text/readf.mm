#! /module/for/moderni/sh

# modernish sys/text/readf
# 
# readf <varname> [ <file> ... ]: concatenate the text file(s) and/or
# standard input into the variable until EOF is reached. A <file> of '-'
# represents standard input. In the absence of <file> arguments, standard
# input is read.
# Unlike with command substitution, only the last linefeed is stripped.
# Text files with no final linefeed (which is invalid) are treated as if they
# have one final linefeed character which is then stripped.
# Text files are always supposed to end in a linefeed, so simply
#	print "$var" > file
#	(which is the same as: printf '%s\n' "$var" > file)
# will correctly write the file back to disk.
#
# --- begin license ---
# Copyright (c) 2016 Martijn Dekker <martijn@inlv.org>, Groningen, Netherlands
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

readf() {
	let "$#" || die "readf: incorrect number of arguments (was $#, must be at least 1)" || return
	case "$1" in
	( '' | [0123456789]* | *[!"$ASCIIALNUM"_]* )
		die "readf: invalid variable name: $1" || return ;;
	esac
	eval "$1=''"
	_Msh_readf_C="
		while IFS='' read -r _Msh_readf_L; do
			$1=\"\${$1:+\${$1}\${CCn}}\${_Msh_readf_L}\"
		done
		empty \"\${_Msh_readf_L}\" || $1=\"\${$1:+\${$1}\${CCn}}\${_Msh_readf_L}\"
	"
	if let "$#"; then
		shift
		while let "$#"; do
			if identic "$1" '-'; then
				eval "${_Msh_readf_C}"
			else
				not is -L dir "$1" || die "readf: $1: Is a directory" || return
				eval "${_Msh_readf_C}" < "$1" || die "readf: failed to read file \"$1\"" || return
			fi
			shift
		done
	else
		eval "${_Msh_readf_C}"
	fi
	unset -v _Msh_readf_C _Msh_readf_L
}

if thisshellhas ROFUNC; then
	readonly -f readf
fi
