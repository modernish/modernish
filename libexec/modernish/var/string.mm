#! /module/for/moderni/sh

# var/string
# String manipulation functions.
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

# trim: Strip whitespace (or other characters) from the beginning and end of
# a variable's value. Whitespace is defined by the 'space' character class
# (in the POSIX locale, this is tab, newline, vertical tab, form feed,
# carriage return, and space, but in other locales it may be different).
# Optionally, a string of literal characters to trim can be provided in the
# second argument; any of those characters will be trimmed from the beginning
# and end of the variable's value.
# Usage: trim <varname> [ <characters> ]
# TODO: options -l and -r for trimming on the left or right only.
if thisshellhas BUG_BRACQUOT; then
	if thisshellhas BUG_NOCHCLASS; then
		print "var/string.mm: You're using a shell with both BUG_BRACQUOT and BUG_NOCHCLASS!" \
			"    This is not known to exist, so workaround not implemented. Please report." 1>&2
		return 1
	fi
	# BUG_BRACQUOT: ksh and zsh don't disable the special meaning of
	# characters -, ! and ^ in quoted bracket expressions (even if their
	# values were passed in variables), so e.g. 'trim var a-d' would trim
	# on 'a', 'b', 'c' and 'd', not 'a', '-' and 'd'.
	# This workaround version makes sure '-' is last in the string, which
	# is the standard way of providing a literal '-' in an unquoted bracket
	# expression.
	# A workaround for an initial '!' or '^' is not needed because the
	# bracket expression in the command substitutions below start with a
	# negating '!' anyway, which makes sure any further '!' or '^' don't
	# have any special meaning.
	trim() {
		case ${#},${1-},${2-} in
		( [12],,"${2-}" | [12],[0123456789]*,"${2-}" | [12],*[!${ASCIIALNUM}_]*,"${2-}" )
			die "trim: invalid variable name: $1" ;;
		( 1,* )	eval "$1=\${$1#\"\${$1%%[![:space:]]*}\"}; $1=\${$1%\"\${$1##*[![:space:]]}\"}" ;;
		( 2,*,*-?* )
			_Msh_trim_P=$2
			replacein -a _Msh_trim_P - ''
			eval "$1=\${$1#\"\${$1%%[!\"\$_Msh_trim_P\"-]*}\"}; $1=\${$1%\"\${$1##*[!\"\$_Msh_trim_P\"-]}\"}"
			unset -v _Msh_trim_P ;;
		( 2,* )	eval "$1=\${$1#\"\${$1%%[!\"\$2\"]*}\"}; $1=\${$1%\"\${$1##*[!\"\$2\"]}\"}" ;;
		( * )	die "trim: incorrect number of arguments (was $#, should be 1 or 2)" ;;
		esac
	}
elif thisshellhas BUG_NOCHCLASS; then
	# pdksh, mksh: POSIX character classes such as [:space:] aren't
	# available, so use modernish $WHITESPACE instead. This means no
	# locale-specific whitespace matching.
	trim() {
		case ${#},${1-} in
		( [12], | [12],[0123456789]* | [12],*[!${ASCIIALNUM}_]* )
			die "trim: invalid variable name: $1" ;;
		( 1,* )	eval "$1=\${$1#\"\${$1%%[!'$WHITESPACE']*}\"}; $1=\${$1%\"\${$1##*[!'$WHITESPACE']}\"}" ;;
		( 2,* )	eval "$1=\${$1#\"\${$1%%[!\"\$2\"]*}\"}; $1=\${$1%\"\${$1##*[!\"\$2\"]}\"}" ;;
		( * )	die "trim: incorrect number of arguments (was $#, should be 1 or 2)" ;;
		esac
	}
else
	# Normal version.
	trim() {
		case ${#},${1-} in
		( [12], | [12],[0123456789]* | [12],*[!${ASCIIALNUM}_]* )
			die "trim: invalid variable name: $1" ;;
		( 1,* )	eval "$1=\${$1#\"\${$1%%[![:space:]]*}\"}; $1=\${$1%\"\${$1##*[![:space:]]}\"}" ;;
		( 2,* )	eval "$1=\${$1#\"\${$1%%[!\"\$2\"]*}\"}; $1=\${$1%\"\${$1##*[!\"\$2\"]}\"}" ;;
		( * )	die "trim: incorrect number of arguments (was $#, should be 1 or 2)" ;;
		esac
	}
fi

# ------------

# replacein: Replace the leading or (-t)railing occurrence or (-a)ll
# occurrences of a string by another string in a variable.
#
# Usage: replacein [ -t | -a ] <varname> <oldstring> <newstring>
#
# TODO: support glob
if thisshellhas PSREPLACE; then
	# bash, *ksh, zsh, yash: we can use ${var/"x"/"y"} and ${var//"x"/"y"}
	replacein() {
		case ${#},${1-},${2-} in
		( 3,,"${2-}" | 3,[0123456789]*,"${2-}" | 3,*[!${ASCIIALNUM}_]*,"${2-}" )
			die "replaceallin: invalid variable name: $1" ;;
		( 4,-[ta], | 4,-[ta],[0123456789]* | 4,-[ta],*[!${ASCIIALNUM}_]* )
			die "replaceallin: invalid variable name: $2" ;;
		( 3,* )	eval "$1=\${$1/\"\$2\"/\"\$3\"}" ;;
		( 4,-t,* )
			eval "if contains \"\$$2\" \"\$3\"; then
				$2=\${$2%\"\$3\"*}\$4\${$2##*\"\$3\"}
			fi" ;;
		( 4,-a,* )
			eval "$2=\${$2//\"\$3\"/\"\$4\"}" ;;
		( * )	die "replaceallin: invalid arguments" ;;
		esac
	}
else
	# POSIX:
	replacein() {
		case ${#},${1-},${2-} in
		( 3,,"${2-}" | 3,[0123456789]*,"${2-}" | 3,*[!${ASCIIALNUM}_]*,"${2-}" )
			die "replaceallin: invalid variable name: $1" ;;
		( 4,-[ta], | 4,-[ta],[0123456789]* | 4,-[ta],*[!${ASCIIALNUM}_]* )
			die "replaceallin: invalid variable name: $2" ;;
		( 3,* )	eval "if contains \"\$$1\" \"\$2\"; then
				$1=\${$1%%\"\$2\"*}\$3\${$1#*\"\$2\"}
			fi" ;;
		( 4,-t,* )
			eval "if contains \"\$$2\" \"\$3\"; then
				$2=\${$2%\"\$3\"*}\$4\${$2##*\"\$3\"}
			fi" ;;
		( 4,-a,* )
			if contains "$4" "$3"; then
				# use a temporary variable to avoid an infinite loop when
				# replacing all of one character by one or more of itself
				# (e.g. "replacein -a somevariable / //")
				eval "_Msh_rAi=\$$2
				$2=
				while contains \"\${_Msh_rAi}\" \"\$3\"; do
					$2=\$$2\${_Msh_rAi%%\"\$3\"*}\$4
					_Msh_rAi=\${_Msh_rAi#*\"\$3\"}
				done
				$2=\$$2\${_Msh_rAi}"
				unset -v _Msh_rAi
			else
				# use faster algorithm without extra variable
				eval "while contains \"\$$2\" \"\$3\"; do
					$2=\${$2%%\"\$3\"*}\$4\${$2#*\"\$3\"}
				done"
			fi ;;
		( * )	die "replaceallin: invalid arguments" ;;
		esac
	}
fi 2>/dev/null

# ------------

# appendsep: Append one or more strings to a variable, separated by a string of
# one or more characters, avoiding the hairy problem of dangling separators.
# Usage: appendsep <varname> <separator> <string> [ <string> ... ]
# For one <string>, this is equivalent to the following incantation:
#	var=${var:+$var$separator}$string
# or (on shells with ADDASSIGN)
#	var+=${var:+$separator}$string
# Example: appendsep PATH : "$HOME/bin" "$HOME/sbin"
#	   appendsep textfiles / *.txt
if thisshellhas ADDASSIGN ARITHCMD ARITHPP; then
	# Use additive assignment var+=value as an optimization if available.
	# (Every shell I know that has ADDASSIGN also has ARITHCMD and ARITHPP; might as well use them.)
	appendsep() {
		case ${#},${1-},${2-} in
		( [12],* )
			die "appendsep: at least 3 arguments expected, got $#" ;;
		( "$#",,"${2-}" | "$#",[0123456789]*,"${2-}" | "$#",*[!${ASCIIALNUM}_]*,"${2-}" )
			die "appendsep: invalid variable name: $1" ;;

		# single string
		( 3,* )	eval "$1+=\${$1:+\$2}\$3" ;;

		# multiple strings with empty or one character separator: use optimization with "$*" and IFS
		# ref.: http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_05_02
		( *,"${1-}", | *,"${1-}",? )
			case ${IFS+s} in (s) _Msh_aS_IFS=$IFS;; (*) unset -v _Msh_aS_IFS;; esac
			IFS=$2
			eval "shift 2; $1+=\${$1:+\$IFS}\$*"
			case ${_Msh_aS_IFS+s} in (s) IFS=${_Msh_aS_IFS}; unset -v _Msh_aS_IFS;; (*) unset -v IFS;; esac ;;

		# multiple strings with multiple character separator: use a loop
		( * )	_Msh_aS_i=2
			while ((++_Msh_aS_i < $#)); do	# ARITHCMD, ARITHPP
				eval "$1+=\${$1:+\$2}\${${_Msh_aS_i}}"
			done
			unset -v _Msh_aS_i ;;
		esac
	}
else
	appendsep() {
		case ${#},${1-},${2-} in
		( [12],* )
			die "appendsep: at least 3 arguments expected, got $#" ;;
		( "$#",,"${2-}" | "$#",[0123456789]*,"${2-}" | "$#",*[!${ASCIIALNUM}_]*,"${2-}" )
			die "appendsep: invalid variable name: $1" ;;

		# single string
		( 3,* )	eval "$1=\${$1:+\$$1\$2}\$3" ;;

		# multiple strings with empty or one character separator: use optimization with "$*" and IFS
		# ref.: http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_05_02
		( *,"${1-}", | *,"${1-}",? )
			case ${IFS+s} in (s) _Msh_aS_IFS=$IFS;; (*) unset -v _Msh_aS_IFS;; esac
			IFS=$2
			eval "shift 2; $1=\${$1:+\$$1\$IFS}\$*"
			case ${_Msh_aS_IFS+s} in (s) IFS=${_Msh_aS_IFS}; unset -v _Msh_aS_IFS;; (*) unset -v IFS;; esac ;;

		# multiple strings with multiple character separator: use a loop
		( * )	_Msh_aS_i=2
			while le _Msh_aS_i+=1 "$#"; do
				eval "$1=\${$1:+\$$1\$2}\${${_Msh_aS_i}}"
			done
			unset -v _Msh_aS_i ;;
		esac
	}
fi

# prependsep: Prepend one or more strings to a variable, separated by a string
# of one or more characters, avoiding the hairy problem of dangling separators.
# The strings are prepended in the order given (not reverse order).
# Usage: prependsep <varname> <separator> <string> [ <string> ... ]
# For one <string>, this is equivalent to the following incantation:
#	var=$string${var:+$separator$var}
# Example: prependsep PATH : "$HOME/bin" "$HOME/sbin"
#	   prependsep textfiles / *.txt
prependsep() {
	case ${#},${1-},${2-} in
	( [12],* )
		die "prependsep: at least 3 arguments expected, got $#" ;;
	( "$#",,"${2-}" | "$#",[0123456789]*,"${2-}" | "$#",*[!${ASCIIALNUM}_]*,"${2-}" )
		die "prependsep: invalid variable name: $1" ;;

	# single string
	( 3,* )	eval "$1=\$3\${$1:+\$2\$$1}" ;;

	# multiple strings with empty or one character separator: use optimization with "$*" and IFS
	# ref.: http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_05_02
	( *,"${1-}", | *,"${1-}",? )
		case ${IFS+s} in (s) _Msh_aS_IFS=$IFS;; (*) unset -v _Msh_aS_IFS;; esac
		IFS=$2
		eval "shift 2; $1=\$*\${$1:+\$IFS\$$1}"
		case ${_Msh_aS_IFS+s} in (s) IFS=${_Msh_aS_IFS}; unset -v _Msh_aS_IFS;; (*) unset -v IFS;; esac ;;

	# multiple strings: use a loop
	( * )	_Msh_pS_i=$#
		while ge _Msh_pS_i-=1 3; do
			eval "$1=\${${_Msh_pS_i}}\${$1:+\$2\$$1}"
		done
		unset -v _Msh_pS_i ;;
	esac
}
