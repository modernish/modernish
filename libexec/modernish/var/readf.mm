#! /module/for/moderni/sh

# var/readf
#
# readf: Read arbitrary data from standard input into a variable until end
# of file, converting it into a format suitable for passing to printf(1).
# This allows storing binary files into shell variables in a textual format
# suitable for manipulation with standard shell utilities.
#
# Usage:
# readf VARNAME
#
# --- begin license ---
# Copyright (c) 2018 Martijn Dekker <martijn@inlv.org>, Groningen, Netherlands
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
	let "$# == 1" || die "readf: 1 variable name expected" || return
	isvarname "$1" || die "readf: invalid variable name: $1" || return
	command eval "$1"'=$(
		command export LC_ALL=C "PATH=$DEFPATH" POSIXLY_CORRECT=y || die "readf: export failed"
		(command od -vb || die "readf: od failed") | command awk '\''
		BEGIN {
			# Build conversion table for ASCII chars 0-126. The index is octal, 0-176.
			for (i=0; i<=31; i++)
				c[sprintf("%o",i)]="OCT";
			for (i=32; i<=126; i++) {
				c[sprintf("%o",i)]=sprintf("%c",i);
			}
			c[7]="\\a";
			c[10]="\\b";
			c[11]="\\t";
			c[12]="\n";	# literal newline
			c[13]="\\v";
			c[14]="\\f";
			c[15]="\\r";
			c[45]="%%";
			c[134]="\\\\";
			prevo=0; 	# flag for: previous char was output as \octal
			odline="";	# up to 16 bytes from "od", converted to printf format
			ORS="";
		}
		NR>1 && NF>1 {
			print odline;
			odline="";
		}
		{
			for (i=2; i<=NF; i++) {
				v=$i+0;  # remove leading zeros from octal number
				if (v>=177 || c[v]=="OCT" || (prevo && v>=60 && v<=67)) {
					odline=(odline)("\\")(v);
					prevo=1;
				} else {
					odline=(odline)(c[v]);
					prevo=0;
				}
			}
		}
		END {
			# print final line; replace a final newline (if any) with \n to
			# defeat stripping of final linefeeds by command substitution.
			if (odline ~ /\n$/)
				print substr(odline,1,length(odline)-1) "\\n";
			else
				print odline;
		}
		'\'' || die "readf: awk failed") || die "readf: assignment failed"
	' || die "readf: eval failed"
}

if thisshellhas ROFUNC; then
	readonly -f readf
fi
