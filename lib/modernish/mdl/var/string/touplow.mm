#! /module/for/moderni/sh
\command unalias tolower toupper _Msh_tmp_getWorkingTr _Msh_tmp_utf8pathSearch 2>/dev/null

# var/string/touplow
#
# toupper and tolower: convert one or more variable's content to upper- and lowercase letters, respectively.
# Usage:	toupper [ <varname> [ <varname> ... ] ]
#		tolower [ <varname> [ <varname> ... ] ]
# If the <varname> argument is omitted, they copy standard input to standard output, converting case.
# NOTE: Some shells or external 'tr' commands cannot convert case in UTF-8 characters in locales using
# these. Modernish tries hard to make one or the other work, but sometimes neither the shell nor
# any external command can handle it. In that case, a warning is printed on init.
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

unset -v MSH_2UP2LOW_NOUTF8

# Determine function definition method.
if thisshellhas KSH93FUNC; then
	# On AT&T ksh93, we *must* define the functions with the 'function' keyword
	# so that 'typeset' makes the temp variable local to the function as expected.
	_Msh_toupper_fn='function toupper {'
	_Msh_tolower_fn='function tolower {'
else
	_Msh_toupper_fn='toupper() {'
	_Msh_tolower_fn='tolower() {'
fi

# Helper function for finding a UTF-8-capable external case conversion command.
_Msh_tmp_utf8pathSearch() {
	push IFS -f; IFS=; set -f
	_Msh_tul_arg=$1; shift
	for _Msh_tul_u do
		isset _Msh_tul_arg && eval "set -- ${_Msh_tul_arg}" && unset -v _Msh_tul_arg
		_Msh_tul_done=:
		IFS=':'; for _Msh_tul_dir in $DEFPATH $PATH; do IFS=
			str begin ${_Msh_tul_dir} '/' || continue
			str in ${_Msh_tul_done} :${_Msh_tul_dir}: && continue
			_Msh_tul_U=${_Msh_tul_dir}/${_Msh_tul_u}
			if can exec ${_Msh_tul_U} \
			&& str eq 'MĲN ΔÉJÀ_ВЮ' $(putln 'mĳn δéjà_вю' | "${_Msh_tul_U}" "$@" 2>/dev/null)
			then
				break 2
			fi
			_Msh_tul_done=${_Msh_tul_done}${_Msh_tul_dir}:
			unset -v _Msh_tul_U
		done
	done
	unset -v _Msh_tul_done _Msh_tul_dir _Msh_tul_u
	pop IFS -f
	isset _Msh_tul_U
}

# Based on available shell features, generate code for the 'eval' within the functions, which are
# themselves 'eval'ed because their code depends on a complex interplay of shell features. So we are
# dealing with two levels of 'eval' below. The specified variable name is always in ${1}.

# First, the default 'tr' commands.
# These may also be needed as a fallback for the 'typeset' method, so use a shell function to init them on demand.
# If we're in a UTF-8 locale, it's very hit-and-miss which command can convert case correctly; modernish will try
# 'tr', 'awk', GNU 'awk' and GNU 'sed' before giving up.
# Basic form is:
#	var=$(put "${var}X" | LC_ALL=(locale) awk '[:lower:]' '[:upper:]') || die "'tr' failed"; var=${var%?}
# ... making sure that LC_ALL is exported to 'tr' with the value of the shell's current locale, and defeating
# command substitution's stripping of final linefeeds by adding a protector character and removing it afterwards.
_Msh_tmp_getWorkingTr() {
	_Msh_a1='${1}=\$(putln \"\${${1}}X\" | '
	_Msh_a2=' failed\"; ${1}=\${${1}%?}'

	case ${LC_ALL:-${LC_CTYPE:-${LANG:-}}} in
	( *[Uu][Tt][Ff]8* | *[Uu][Tt][Ff]-8* )
		# Try to find a command that will correctly convert UTF-8 case.
		if _Msh_tmp_utf8pathSearch "'[:lower:]' '[:upper:]'" tr gtr; then
			_Msh_tr1="${_Msh_a1}${_Msh_tul_U} "
			_Msh_tr2=": 'tr'${_Msh_a2}"
			_Msh_toupper_tr="${_Msh_tr1}'[:lower:]' '[:upper:]') || die \\\"toupper${_Msh_tr2}"
			_Msh_tolower_tr="${_Msh_tr1}'[:upper:]' '[:lower:]') || die \\\"tolower${_Msh_tr2}"
		elif _Msh_tmp_utf8pathSearch \''{print toupper($0)}'\' awk gawk; then
			_Msh_tr1="${_Msh_a1}${_Msh_tul_U} "
			_Msh_tr2=": 'awk'${_Msh_a2}"
			_Msh_toupper_tr="${_Msh_tr1}'{print toupper(\\\$0)}') || die \\\"toupper${_Msh_tr2}"
			_Msh_tolower_tr="${_Msh_tr1}'{print tolower(\\\$0)}') || die \\\"tolower${_Msh_tr2}"
		elif _Msh_tmp_utf8pathSearch \''s/\(.*\)/\U\1/'\' gnused gsed sed; then
			_Msh_tr1="${_Msh_a1}${_Msh_tul_U} "
			_Msh_tr2=": GNU 'sed'${_Msh_a2}"
			_Msh_toupper_tr="${_Msh_tr1}'s/\\(.*\\)/\\U\\1/') || die \\\"toupper${_Msh_tr2}"
			_Msh_tolower_tr="${_Msh_tr1}'s/\\(.*\\)/\\L\\1/') || die \\\"tolower${_Msh_tr2}"
		else
			# Use LC_ALL=C and don't use character classes to avoid garbling UTF-8 chars on broken systems.
			_Msh_tr1="${_Msh_a1}LC_ALL=C PATH=\\\$DEFPATH command tr "
			_Msh_tr2=": 'tr'${_Msh_a2}"
			_Msh_toupper_tr="${_Msh_tr1}a-z A-Z) || die \\\"toupper${_Msh_tr2}"
			_Msh_tolower_tr="${_Msh_tr1}A-Z a-z) || die \\\"tolower${_Msh_tr2}"
			# return unsuccessfully to indicate we're in UTF-8 locale but can only convert ASCII
			unset -v _Msh_a1 _Msh_a2 _Msh_tr1 _Msh_tr2
			putln "var/string/touplow: warning: cannot convert case in UTF-8 characters" >&2
			MSH_2UP2LOW_NOUTF8=y
			return 1
		fi
		unset -v _Msh_tul_U ;;
	( * )	# Non-UTF-8 locale: check if 'tr' supports character classes. (Busybox 'tr' doesn't!)
		_Msh_test=$(putln 'abcxyz' | PATH=$DEFPATH exec tr '[:lower:]' '[:upper:]')
		_Msh_tr1="${_Msh_a1}PATH=\\\$DEFPATH command tr "
		_Msh_tr2=": 'tr'${_Msh_a2}"
		case ${_Msh_test} in
		(ABCXYZ)_Msh_toupper_tr="${_Msh_tr1}'[:lower:]' '[:upper:]') || die \\\"toupper${_Msh_tr2}"
			_Msh_tolower_tr="${_Msh_tr1}'[:upper:]' '[:lower:]') || die \\\"tolower${_Msh_tr2}" ;;
		( * )	_Msh_toupper_tr="${_Msh_tr1}'[a-z]' '[A-Z]') || die \\\"toupper${_Msh_tr2}"
			_Msh_tolower_tr="${_Msh_tr1}'[A-Z]' '[a-z]') || die \\\"tolower${_Msh_tr2}" ;;
		esac
	esac
	unset -v _Msh_a1 _Msh_a2 _Msh_tr1 _Msh_tr2
}

if thisshellhas typeset &&
	typeset -u _Msh_test 2>/dev/null && _Msh_test=gr@lDru1S && str eq "${_Msh_test}" GR@LDRU1S && unset -v _Msh_test &&
	typeset -l _Msh_test 2>/dev/null && _Msh_test=gr@lDru1S && str eq "${_Msh_test}" gr@ldru1s && unset -v _Msh_test
then	# We can use 'typeset -u' and 'typeset -l' for variables. This is best: we don't need any external commands.
	_Msh_toupper_ts='typeset -u mystring; mystring=\$${1}; ${1}=\$mystring'
	_Msh_tolower_ts='typeset -l mystring; mystring=\$${1}; ${1}=\$mystring'
	# However, sometimes these only support ASCII characters, so do an additional check for non-ASCII --
	# actually just UTF-8 because that's the de facto standard these days. If 'typeset' is lacking for
	# UTF-8, do the same test for an external command and add it as a fallback if it does better.
	case ${LC_ALL:-${LC_CTYPE:-${LANG:-}}} in
	( *[Uu][Tt][Ff]8* | *[Uu][Tt][Ff]-8* )
		typeset -u _Msh_test
		_Msh_test='mĳn δéjà_вю'
		case ${_Msh_test} in
		( 'MĲN ΔÉJÀ_ВЮ' )
			# It worked correctly; use typeset instead of 'awk'
			_Msh_toupper_tr=${_Msh_toupper_ts}
			_Msh_tolower_tr=${_Msh_tolower_ts} ;;
		( M*N\ *J*_* )
			# It didn't transform all the UTF-8. Check if an external command does better.
			if _Msh_tmp_getWorkingTr; then
				_Msh_case_nonascii='case \$${1} in ( *[!\"\$ASCIICHARS\"]* )'
				_Msh_toupper_tr="${_Msh_case_nonascii} ${_Msh_toupper_tr} ;; ( * ) ${_Msh_toupper_ts} ;; esac"
				_Msh_tolower_tr="${_Msh_case_nonascii} ${_Msh_tolower_tr} ;; ( * ) ${_Msh_tolower_ts} ;; esac"
				unset -v _Msh_case_nonascii
			else	# still not better: give up and just use 'typeset'
				_Msh_toupper_tr=${_Msh_toupper_ts}
				_Msh_tolower_tr=${_Msh_tolower_ts}
			fi ;;
		( * ) _Msh_initExit "toupper/tolower init: 'typeset -u' failed!" \
				"${CCt}(bad result: '${_Msh_test}')" ;;
		esac
		unset -v _Msh_test ;;
	( * )	# No UTF-8: assume ASCII
		_Msh_toupper_tr=${_Msh_toupper_ts}
		_Msh_tolower_tr=${_Msh_tolower_ts} ;;
	esac
	unset -v _Msh_toupper_ts _Msh_tolower_ts _Msh_toupper_TS _Msh_tolower_TS
# If we don't have 'typeset -u/-l', use an external command. Try hard to avoid an expensive no-op invocation.
elif thisshellhas BUG_NOCHCLASS; then
	# BUG_NOCHCLASS means no (or broken) character classes. All we can portably do to minimise unnecessary external
	# command invocations is check for upper/lowercase *only* if the string is pure ASCII. (Using '*[a-z]*' or
	# '*[A-Z]*' is not good enough as this may let non-ASCII characters slip, depending on the locale. So use the
	# modernish system constants $ASCIILOWER and $ASCIIUPPER which enumerate the entire ASCII alphabet.)
	if _Msh_tmp_getWorkingTr; then
		_Msh_toupper_tr='case \$${1} in ( *[!\"\$ASCIICHARS\"]* | *[\"\$ASCIILOWER\"]* ) '"${_Msh_toupper_tr} ;; esac"
		_Msh_tolower_tr='case \$${1} in ( *[!\"\$ASCIICHARS\"]* | *[\"\$ASCIIUPPER\"]* ) '"${_Msh_tolower_tr} ;; esac"
	else	# No external command converts non-ASCII, so it's pointless to check for non-ASCII chars.
		_Msh_toupper_tr='case \$${1} in ( *[\"\$ASCIILOWER\"]* ) '"${_Msh_toupper_tr} ;; esac"
		_Msh_tolower_tr='case \$${1} in ( *[\"\$ASCIIUPPER\"]* ) '"${_Msh_tolower_tr} ;; esac"
	fi
elif thisshellhas WRN_MULTIBYTE; then
	# We've got good character classes, but we're in a UTF-8 locale on a shell that does not support UTF-8.
	# A similar workaround is needed: check for pure ASCII before using character classes.
	# (The [:ascii:] class is not POSIX, so we still can't use it.)
	if _Msh_tmp_getWorkingTr; then
		_Msh_toupper_tr='case \$${1} in ( *[!\"\$ASCIICHARS\"]* | *[[:lower:]]* ) '"${_Msh_toupper_tr} ;; esac"
		_Msh_tolower_tr='case \$${1} in ( *[!\"\$ASCIICHARS\"]* | *[[:upper:]]* ) '"${_Msh_tolower_tr} ;; esac"
	else	# No external command converts non-ASCII, so it's pointless to check for non-ASCII chars.
		_Msh_toupper_tr='case \$${1} in ( *[[:lower:]]* ) '"${_Msh_toupper_tr} ;; esac"
		_Msh_tolower_tr='case \$${1} in ( *[[:upper:]]* ) '"${_Msh_tolower_tr} ;; esac"
	fi
else
	# This shell has neither problem, so we can reliably avoid invoking an external command unnecessarily.
	_Msh_tmp_getWorkingTr
	_Msh_toupper_tr='case \$${1} in ( *[[:lower:]]* ) '"${_Msh_toupper_tr} ;; esac"
	_Msh_tolower_tr='case \$${1} in ( *[[:upper:]]* ) '"${_Msh_tolower_tr} ;; esac"
fi

# With all the code for this shell/OS combination gathered, now define the functions.
eval "${_Msh_toupper_fn}"'
	let "$#" || die "toupper: need at least 1 argument, got $#"
	while	str isvarname "$1" || die "toupper: invalid variable name: $1"
		eval "'"${_Msh_toupper_tr}"'"
		shift
		let "$#"
	do :; done
}
'"${_Msh_tolower_fn}"'
	let "$#" || die "tolower: need at least 1 argument, got $#"
	while	str isvarname "$1" || die "tolower: invalid variable name: $1"
		eval "'"${_Msh_tolower_tr}"'"
		shift
		let "$#"
	do :; done
}'

unset -v _Msh_toupper_fn _Msh_tolower_fn _Msh_toupper_tr _Msh_tolower_tr _Msh_toupper_TR _Msh_tolower_TR
unset -f _Msh_tmp_getWorkingTr _Msh_tmp_utf8pathSearch
readonly MSH_2UP2LOW_NOUTF8

if thisshellhas ROFUNC; then
	readonly -f toupper tolower
fi
