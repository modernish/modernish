#! /module/for/moderni/sh
\command unalias replacein 2>/dev/null

# var/string/replacein
#
# replacein: Replace the leading or (-t)railing occurrence or (-a)ll
# occurrences of a string by another string in a variable.
#
# Usage: replacein [ -t | -a ] <varname> <oldstring> <newstring>
#
# TODO: support glob
# TODO: reconsider option letters
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

if thisshellhas PSREPLACE; then
	# bash, *ksh, zsh, yash: we can use ${var/"x"/"y"} and ${var//"x"/"y"}
	replacein() {
		case ${#},${1-},${2-} in
		( 3,,"${2-}" | 3,[0123456789]*,"${2-}" | 3,*[!"$ASCIIALNUM"_]*,"${2-}" )
			die "replacein: invalid variable name: $1" ;;
		( 4,-[ta], | 4,-[ta],[0123456789]* | 4,-[ta],*[!"$ASCIIALNUM"_]* )
			die "replacein: invalid variable name: $2" ;;
		( 3,* )	eval "$1=\${$1/\"\$2\"/\"\$3\"}" ;;
		( 4,-t,* )
			eval "if str in \"\$$2\" \"\$3\"; then
				$2=\${$2%\"\$3\"*}\$4\${$2##*\"\$3\"}
			fi" ;;
		( 4,-a,* )
			eval "$2=\${$2//\"\$3\"/\"\$4\"}" ;;
		( * )	die "replacein: invalid arguments" ;;
		esac
	}
else
	# POSIX:
	replacein() {
		case ${#},${1-},${2-} in
		( 3,,"${2-}" | 3,[0123456789]*,"${2-}" | 3,*[!"$ASCIIALNUM"_]*,"${2-}" )
			die "replacein: invalid variable name: $1" ;;
		( 4,-[ta], | 4,-[ta],[0123456789]* | 4,-[ta],*[!"$ASCIIALNUM"_]* )
			die "replacein: invalid variable name: $2" ;;
		( 3,* )	eval "if str in \"\$$1\" \"\$2\"; then
				$1=\${$1%%\"\$2\"*}\$3\${$1#*\"\$2\"}
			fi" ;;
		( 4,-t,* )
			eval "if str in \"\$$2\" \"\$3\"; then
				$2=\${$2%\"\$3\"*}\$4\${$2##*\"\$3\"}
			fi" ;;
		( 4,-a,* )
			if str in "$4" "$3"; then
				# use a temporary variable to avoid an infinite loop when
				# replacing all of one character by one or more of itself
				# (e.g. "replacein -a somevariable / //")
				eval "_Msh_rAi=\$$2
				$2=
				while str in \"\${_Msh_rAi}\" \"\$3\"; do
					$2=\$$2\${_Msh_rAi%%\"\$3\"*}\$4
					_Msh_rAi=\${_Msh_rAi#*\"\$3\"}
				done
				$2=\$$2\${_Msh_rAi}"
				unset -v _Msh_rAi
			else
				# use faster algorithm without extra variable
				eval "while str in \"\$$2\" \"\$3\"; do
					$2=\${$2%%\"\$3\"*}\$4\${$2#*\"\$3\"}
				done"
			fi ;;
		( * )	die "replacein: invalid arguments" ;;
		esac
	}
fi

if thisshellhas ROFUNC; then
	readonly -f replacein
fi
