#! /module/for/moderni/sh
\command unalias putr putrln 2>/dev/null

# putr: repeatedly output string of characters.
# putrln: putr followed by a newline.
#
# Usage: putr NUMBER STRING
#	 putrln NUMBER STRING
#
# If NUMBER is '-', then the length is the line length of the terminal
# divided by the number of characters in STRING, rounded down.
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

unset -v _Msh_putr_ln

putr() {
	let "$# == 2" || die "putr${_Msh_putr_ln-}: need 2 arguments, got $#"
	case $1 in
	( - )	# determine terminal line length
		_Msh_putr_n=${COLUMNS:=$(PATH=$DEFPATH command tput cols)}
		str isint "${_Msh_putr_n}" && let "_Msh_putr_n >= 0" || _Msh_putr_n=80
		# divide it by the length of the string
		if thisshellhas WRN_MULTIBYTE && str match "$2" "*[!$ASCIICHARS]*"; then
			_Msh_putr_n=$(( _Msh_putr_n / $(put "$2" | PATH=$DEFPATH command wc -m \
				|| die "putr${_Msh_putr_ln-}: 'wc' failed") ))
		else
			_Msh_putr_n=$(( _Msh_putr_n / ${#2} ))
		fi
		set -- "${_Msh_putr_n}" "$2"
		unset -v _Msh_putr_n ;;
	( * )	str isint "$1" && let "$1 >= 0" || die "putr${_Msh_putr_ln-}: invalid number: $1" ;;
	esac
	PATH=$DEFPATH _Msh_putr_s=$2 command awk -v "n=$(( $1 ))" \
		'BEGIN {
			ORS="";
			for (i = 1; i <= n; i++) print ENVIRON["_Msh_putr_s"];
			if ("_Msh_putr_ln" in ENVIRON) print "\n";
		}' \
	|| { let "$? > 125 && $? != SIGPIPESTATUS" && die "putr${_Msh_putr_ln-}: awk failed"; }
}

putrln() {
	export _Msh_putr_ln='ln'
	putr "$@"
	unset -v _Msh_putr_ln
}

if thisshellhas ROFUNC; then
	readonly -f putr putrln
fi
