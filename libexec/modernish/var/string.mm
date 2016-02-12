#! /module/for/moderni/sh

# var/string
# String manipulation functions.
#
# So far, this module has:
#	- trim: Strip whitespace or other characters from the beginning and
#	  end of a variable's value.
#	- replacein: Replace the leading or trailing occurrence or all
#	  occurrences of a string by another string in a variable.
#	- append: Append one or more strings to a variable, separated by
#	  a string of one or more characters, avoiding the hairy problem of
#	  dangling separators.
#	- prepend: Prepend one or more strings to a variable, separated
#	  by a string of one or more characters, avoiding the hairy problem
#	  of dangling separators.
# TODO:
#	- repeatc: Repeat a character or string n times.
#	- splitc: Split a string into individual characters.
#	- leftstr: Get the left n characters of a string.
#	- midstr: Get n characters from position x in a string.
#	- rightstr: Get the right n characters of a string.
#	- toupper: convert to upper case
#	- tolower: convert to lower case
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
	# BUG_BRACQUOT: ksh93 and zsh don't disable the special meaning of
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
# TODO: reconsider option letters
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

# append: Append zero or more strings to a variable, separated by a string of
# zero or more characters, avoiding the hairy problem of dangling separators.
#
# Usage: append [ --sep=<separator> ] [ -Q ] <varname> [ <string> ... ]
# If the separator is not specified, it defaults to a space character.
# If the -Q option is given, each <string> is shell-quoted before appending.
#
# For one <string>, this function is equivalent to the following incantation:
#	var=${var:+$var$separator}$string
# or (on shells with ADDASSIGN)
#	var+=${var:+$separator}$string
# Example: append --sep=: PATH "$HOME/bin" "$HOME/sbin"
#	   append --sep=/ textfiles *.txt
#
# (This function uses a GNU-style long option of the form --sep=<separator>
# because it is a safer way of dealing with empty removal. With a classical
# option format such as '-s <separator>' or '-s<separator>', even under 'use
# safe', if the separator is passed from an empty variable, the variable
# name will be taken as the separator, and the first string as the variable
# name. Also, due to the way the shell removes quotes before passing
# arguments to commands, a zero character separator could never be stacked
# with an -s option in a single word, even if it is quoted -- it has to be a
# separate empty word. The GNU long option format avoids both these snags,
# allowing an empty separator to be safely passed from an unquoted variable
# under 'use safe'.)

if thisshellhas ADDASSIGN ARITHCMD ARITHPP; then
	# Use additive assignment var+=value as an optimization if available.
	# (Every shell I know that has ADDASSIGN also has ARITHCMD and ARITHPP; might as well use them.)
	append() {
		_Msh_aS_Q=n
		_Msh_aS_s=' '
		while	case ${1-} in
			( --sep=* )
				_Msh_aS_s=${1#--sep=} ;;
			( -Q )	_Msh_aS_Q=y ;;
			( -- )	! shift ;;
			( -* )	die "append: invalid option: $1" || return ;;
			( * )	! : ;;
			esac
		do
			shift
		done
		case ${_Msh_aS_Q},${#},${1-},${_Msh_aS_s} in
		( ?,0,,"${_Msh_aS_s}" )
			die "append: variable name expected" || return ;;
		( ?,"$#",,"${_Msh_aS_s}" | ?,"$#",[0123456789]*,"${_Msh_aS_s}" | ?,"$#",*[!${ASCIIALNUM}_]*,"${_Msh_aS_s}" )
			die "append: invalid variable name: $1" || return;;

		# no strings: no-op (in case of empty removal)
		( ?,1,* ) ;;

		# single string
		( n,2,* )
			eval "$1+=\${$1:+\${_Msh_aS_s}}\$2" ;;

		# multiple strings with empty or one character separator: use optimization with "$*" and IFS
		# ref.: http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_05_02
		( n,*,"${1-}", | n,*,"${1-}",? )
			isset IFS && _Msh_aS_IFS=$IFS || unset -v _Msh_aS_IFS
			IFS=${_Msh_aS_s}
			eval "shift; $1+=\${$1:+\$IFS}\$*"
			isset _Msh_aS_IFS && IFS=${_Msh_aS_IFS} && unset -v _Msh_aS_IFS || unset -v IFS ;;

		# multiple strings with multiple character separator: use a loop
		( n,* )	_Msh_aS_i=2
			while ((++_Msh_aS_i < $#)); do	# ARITHCMD, ARITHPP
				eval "$1+=\${$1:+\${_Msh_aS_s}}\${${_Msh_aS_i}}"
			done
			unset -v _Msh_aS_i ;;

		# single string (with shell quoting)
		( y,2,* )
			_Msh_aS_V=$2
			shellquote -f _Msh_aS_V || die "append: 'shellquote' failed" || return
			eval "$1+=\${$1:+\${_Msh_aS_s}}\${_Msh_aS_V}"
			unset -v _Msh_aS_V ;;

		# multiple strings (with shell quoting)
		( y,* )	_Msh_aS_i=2
			while ((++_Msh_aS_i < $#)); do	# ARITHCMD, ARITHPP
				eval "_Msh_aS_V=\${${_Msh_aS_i}}
					shellquote -f _Msh_aS_V || die \"append: 'shellquote' failed\" || return
					$1+=\${$1:+\${_Msh_aS_s}}\${_Msh_aS_V}"
			done
			unset -v _Msh_aS_i _Msh_aS_V ;;
		esac
			
		unset -v _Msh_aS_s _Msh_aS_Q
	}
else
	append() {
		_Msh_aS_Q=n
		_Msh_aS_s=' '
		while	case ${1-} in
			( --sep=* )
				_Msh_aS_s=${1#--sep=} ;;
			( -Q )	_Msh_aS_Q=y ;;
			( -- )	! shift ;;
			( -* )	die "append: invalid option: $1" || return ;;
			( * )	! : ;;
			esac
		do
			shift
		done
		case ${_Msh_aS_Q},${#},${1-},${_Msh_aS_s} in
		( ?,0,,"${_Msh_aS_s}" )
			die "append: variable name expected" || return ;;
		( ?,"$#",,"${_Msh_aS_s}" | ?,"$#",[0123456789]*,"${_Msh_aS_s}" | ?,"$#",*[!${ASCIIALNUM}_]*,"${_Msh_aS_s}" )
			die "append: invalid variable name: $1" || return;;

		# no strings: no-op (in case of empty removal)
		( ?,1,* ) ;;

		# single string
		( n,2,* )
			eval "$1=\${$1:+\$$1\${_Msh_aS_s}}\$2" ;;

		# multiple strings with empty or one character separator: use optimization with "$*" and IFS
		# ref.: http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_05_02
		( n,*,"${1-}", | n,*,"${1-}",? )
			isset IFS && _Msh_aS_IFS=$IFS || unset -v _Msh_aS_IFS
			IFS=${_Msh_aS_s}
			eval "shift; $1=\${$1:+\$$1\$IFS}\$*"
			isset _Msh_aS_IFS && IFS=${_Msh_aS_IFS} && unset -v _Msh_aS_IFS || unset -v IFS ;;

		# multiple strings with multiple character separator: use a loop
		( n,* )	_Msh_aS_i=1
			while let "(_Msh_aS_i+=1) <= $#"; do
				eval "$1=\${$1:+\$$1\${_Msh_aS_s}}\${${_Msh_aS_i}}"
			done
			unset -v _Msh_aS_i ;;

		# single string (with shell quoting)
		( y,2,* )
			_Msh_aS_V=$2
			shellquote -f _Msh_aS_V || die "append: 'shellquote' failed" || return
			eval "$1=\${$1:+\$$1\${_Msh_aS_s}}\${_Msh_aS_V}"
			unset -v _Msh_aS_V ;;

		# multiple strings (with shell quoting)
		( y,* )	_Msh_aS_i=1
			while let "(_Msh_aS_i+=1) <= $#"; do
				eval "_Msh_aS_V=\${${_Msh_aS_i}}
					shellquote -f _Msh_aS_V || die \"append: 'shellquote' failed\" || return
					$1=\${$1:+\$$1\${_Msh_aS_s}}\${_Msh_aS_V}"
			done
			unset -v _Msh_aS_i _Msh_aS_V ;;
		esac

		unset -v _Msh_aS_s _Msh_aS_Q
	}
fi

# prepend: Exactly like append() but adds strings at the start instead of
# the end (but without reversing the order they are specified in).
# For one <string>, this is equivalent to the following incantation:
#	var=$string${var:+$separator$var}
prepend() {
	_Msh_pS_Q=n
	_Msh_pS_s=' '
	while	case ${1-} in
		( --sep=* )
			_Msh_pS_s=${1#--sep=} ;;
		( -Q )	_Msh_pS_Q=y ;;
		( -- )	! shift ;;
		( -* )	die "prepend: invalid option: $1" || return ;;
		( * )	! : ;;
		esac
	do
		shift
	done
	case ${_Msh_pS_Q},${#},${1-},${_Msh_pS_s} in
	( ?,0,,"${_Msh_pS_s}" )
		die "prepend: variable name expected" || return ;;
	( ?,"$#",,"${_Msh_pS_s}" | ?,"$#",[0123456789]*,"${_Msh_pS_s}" | ?,"$#",*[!${ASCIIALNUM}_]*,"${_Msh_pS_s}" )
		die "prepend: invalid variable name: $1" || return;;

	# no strings: no-op (in case of empty removal)
	( ?,1,* ) ;;

	# single string
	( n,2,* )
		eval "$1=\$2\${$1:+\${_Msh_pS_s}\$$1}" ;;

	# multiple strings with empty or one character separator: use optimization with "$*" and IFS
	# ref.: http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_05_02
	( n,*,"${1-}", | n,*,"${1-}",? )
		isset IFS && _Msh_pS_IFS=$IFS || unset -v _Msh_pS_IFS
		IFS=${_Msh_pS_s}
		eval "shift; $1=\$*\${$1:+\$IFS\$$1}"
		isset _Msh_pS_IFS && IFS=${_Msh_pS_IFS} && unset -v _Msh_pS_IFS || unset -v IFS ;;

	# multiple strings with multiple character separator: use a loop
	( n,* )	let "_Msh_pS_i=${#}+1"
		while let "(_Msh_pS_i-=1) >= 2"; do
			eval "$1=\${${_Msh_pS_i}}\${$1:+\${_Msh_pS_s}\$$1}"
		done
		unset -v _Msh_pS_i ;;

	# single string (with shell quoting)
	( y,2,* )
		_Msh_pS_V=$2
		shellquote -f _Msh_pS_V || die "append: 'shellquote' failed" || return
		eval "$1=\${_Msh_pS_V}\${$1:+\${_Msh_pS_s}\$$1}"
		unset -v _Msh_pS_V ;;

	# multiple strings (with shell quoting)
	( y,* )	let "_Msh_pS_i=${#}+1"
		while let "(_Msh_pS_i-=1) >= 2"; do
			eval "_Msh_pS_V=\${${_Msh_pS_i}}
				shellquote -f _Msh_pS_V || die \"append: 'shellquote' failed\" || return
				$1=\${_Msh_pS_V}\${$1:+\${_Msh_pS_s}\$$1}"
		done
		unset -v _Msh_pS_i _Msh_pS_V ;;
	esac

	unset -v _Msh_pS_s _Msh_pS_Q
}
