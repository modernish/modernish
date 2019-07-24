#! /module/for/moderni/sh
\command unalias readf 2>/dev/null

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

readf() {
	unset -v _Msh_rFo_h
	forever do
		case ${1-} in
		( -h )	export _Msh_rFo_h=y ;;
		( -- )	shift; break ;;
		( -* )	die "readf: invalid option: $1" ;;
		( * )	break ;;
		esac
		shift
	done
	let "$# == 1" || die "readf: 1 variable name expected"
	str isvarname "$1" || die "readf: invalid variable name: $1"
	command eval "$1"'=$(
		command export LC_ALL=C "PATH=$DEFPATH" POSIXLY_CORRECT=y || die "readf: export failed"
		(command od -vb || die "readf: od failed") | command awk '\''
		BEGIN {
			# Build conversion table for ASCII chars 0-127 and high-byte 128-255.
			# The index is octal, 0-377, so we can directly parse the output of "od -vb".
			for (i=0; i<=31; i++)
				c[sprintf("%o",i)]="OCT";
			for (i=32; i<=255; i++) {
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
				if ( (v>=200 && ENVIRON["_Msh_rFo_h"]=="y") ||
				  ! (v>=177 || c[v]=="OCT" || (prevo && v>=60 && v<=67)) ) {
					odline=(odline)(c[v]);
					prevo=0;
				} else {
					odline=(odline)("\\")(v);
					prevo=1;
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
	unset -v _Msh_rFo_h
}

if thisshellhas ROFUNC; then
	readonly -f readf
fi
