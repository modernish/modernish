#! /module/for/moderni/sh
\command unalias shellquote shellquoteparams _Msh_qV_R _Msh_qV_dblQuote _Msh_qV_sngQuote _Msh_qV_sngQuote_do1fld 2>/dev/null

# var/shellquote: efficient, fast, safe and portable shellquoting algorithm.
#
# ___ shellquote ______________________________________________________________
# Shell-quote the values of one or more variables to prepare them for
# safe use with "eval" or other parsing by the shell. If a value only
# contains shell-safe characters, it leaves it unquoted. Empty values
# are quoted.
#
# Usage: shellquote [ <options> ] <varname> ... [ [ <options> ] <varname> ... ]
#
# Options take effect for all variable names following them. Each option
# must be a separate argument.
# -f	Force quoting: disable size optimisations that allow unquoted characters.
# +f	Don't quote if value only contains shell-safe characters. (Default)
# -P	Generate POSIX Portable quoted strings, that may span multiple lines.
# +P	One-line quoted strings, double-quoting linefeeds with $CCn. (Default)
#
# ___ shellquoteparams ________________________________________________________
# shellquoteparams: Shell-quote all the positional parameters in-place.
# Usage: shellquoteparams (no arguments)
# To unquote them again, do:
#	eval "set -- $@"
# (be sure they are quoted before unquoting, or havoc will be wreaked!)
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

# Internal function for shellquote() that POSIX-shellquotes one field (split by single quote).
if thisshellhas ADDASSIGN; then
	_Msh_qV_sngQuote_do1fld() {
		# Unless -f was given, optimise for size by backslash-escaping single-character
		# fields and leaving fields containing only shell-safe characters unquoted.
		case ${_Msh_qV_f},${_Msh_qV_C} in
		( , | f, )
			_Msh_qV+=\\\' ;;
		( ,[!$CCn$SHELLSAFECHARS]* )
			# If the field starts with a single non-linefeed, non-shellsafe char and otherwise contains
			# nothing or only shellsafe chars, then backslash-escape it. Otherwise, single-quote.
			case ${_Msh_qV_C#?} in
			( *[!$SHELLSAFECHARS]* )
				_Msh_qV+=\'${_Msh_qV_C}\'\\\' ;;
			( * )	_Msh_qV+=\\${_Msh_qV_C}\\\' ;;
			esac ;;
		( ,*[!$SHELLSAFECHARS]* | f,* )
			# Non-shellsafe chars or -f: single-quote the field.
			_Msh_qV+=\'${_Msh_qV_C}\'\\\' ;;
		( * )	# Only shellsafe chars and no -f: don't quote.
			_Msh_qV+=${_Msh_qV_C}\\\' ;;
		esac
	}
else
	_Msh_qV_sngQuote_do1fld() {
		# Unless -f was given, optimise for size by backslash-escaping single-character
		# fields and leaving fields containing only shell-safe characters unquoted.
		case ${_Msh_qV_f},${_Msh_qV_C} in
		( , | f, )
			_Msh_qV=${_Msh_qV}\\\' ;;
		( ,[!$CCn$SHELLSAFECHARS]* )
			# If the field starts with a single non-linefeed, non-shellsafe char and otherwise contains
			# nothing or only shellsafe chars, then backslash-escape it. Otherwise, single-quote.
			case ${_Msh_qV_C#?} in
			( *[!$SHELLSAFECHARS]* )
				_Msh_qV=${_Msh_qV}\'${_Msh_qV_C}\'\\\' ;;
			( * )	_Msh_qV=${_Msh_qV}\\${_Msh_qV_C}\\\' ;;
			esac ;;
		( ,*[!$SHELLSAFECHARS]* | f,* )
			# Non-shellsafe chars or -f: single-quote the field.
			_Msh_qV=${_Msh_qV}\'${_Msh_qV_C}\'\\\' ;;
		( * )	# Only shellsafe chars and no -f: don't quote.
			_Msh_qV=${_Msh_qV}${_Msh_qV_C}\\\' ;;
		esac
	}
fi

# Internal function for shellquote() that single-quotes a string, possibly mixed
# with backslash quoting or leaving parts with only shellsafe characters unquoted.
_Msh_qV_sngQuote() {
	# Field-split the value at its single quote characters (at least 1, makes min. 2 fields).
	case ${_Msh_qV_VAL} in
	( *\' )	# On most shells, non-whitespace IFS discards a final empty field, so add one.
		thisshellhas QRK_IFSFINAL || _Msh_qV_VAL=${_Msh_qV_VAL}\' ;;
	esac
	_Msh_qV=
	push IFS -f; set -f
	IFS="'"; for _Msh_qV_C in ${_Msh_qV_VAL}; do IFS=
		# Quote each field, appending backslash-escaped literal single quotes.
		_Msh_qV_sngQuote_do1fld
	done
	pop IFS -f
	# End. Remove one superfluous backslash-escaped single quote.
	_Msh_qV_VAL=${_Msh_qV%\\\'}
}

# Internal function for shellquote() to double-quote a string, replacing control
# characters with modernish $CC*. This guarantees a one-line, printable quoted string.
if thisshellhas PSREPLACE; then
	eval '_Msh_qV_dblQuote() {
		_Msh_qV=${_Msh_qV_VAL//\\/\\\\}
		_Msh_qV=${_Msh_qV//\$/\\\$}
		_Msh_qV=${_Msh_qV//\`/\\\`}
		case ${_Msh_qV_VAL} in
		( *[$CONTROLCHARS]* )
			_Msh_qV=${_Msh_qV//$CC01/'\''${CC01}'\''}
			_Msh_qV=${_Msh_qV//$CC02/'\''${CC02}'\''}
			_Msh_qV=${_Msh_qV//$CC03/'\''${CC03}'\''}
			_Msh_qV=${_Msh_qV//$CC04/'\''${CC04}'\''}
			_Msh_qV=${_Msh_qV//$CC05/'\''${CC05}'\''}
			_Msh_qV=${_Msh_qV//$CC06/'\''${CC06}'\''}
			_Msh_qV=${_Msh_qV//$CC07/'\''${CCa}'\''}
			_Msh_qV=${_Msh_qV//$CC08/'\''${CCb}'\''}
			_Msh_qV=${_Msh_qV//$CC09/'\''${CCt}'\''}
			_Msh_qV=${_Msh_qV//$CC0A/'\''${CCn}'\''}
			_Msh_qV=${_Msh_qV//$CC0B/'\''${CCv}'\''}
			_Msh_qV=${_Msh_qV//$CC0C/'\''${CCf}'\''}
			_Msh_qV=${_Msh_qV//$CC0D/'\''${CCr}'\''}
			_Msh_qV=${_Msh_qV//$CC0E/'\''${CC0E}'\''}
			_Msh_qV=${_Msh_qV//$CC0F/'\''${CC0F}'\''}
			_Msh_qV=${_Msh_qV//$CC10/'\''${CC10}'\''}
			_Msh_qV=${_Msh_qV//$CC11/'\''${CC11}'\''}
			_Msh_qV=${_Msh_qV//$CC12/'\''${CC12}'\''}
			_Msh_qV=${_Msh_qV//$CC13/'\''${CC13}'\''}
			_Msh_qV=${_Msh_qV//$CC14/'\''${CC14}'\''}
			_Msh_qV=${_Msh_qV//$CC15/'\''${CC15}'\''}
			_Msh_qV=${_Msh_qV//$CC16/'\''${CC16}'\''}
			_Msh_qV=${_Msh_qV//$CC17/'\''${CC17}'\''}
			_Msh_qV=${_Msh_qV//$CC18/'\''${CC18}'\''}
			_Msh_qV=${_Msh_qV//$CC19/'\''${CC19}'\''}
			_Msh_qV=${_Msh_qV//$CC1A/'\''${CC1A}'\''}
			_Msh_qV=${_Msh_qV//$CC1B/'\''${CCe}'\''}
			_Msh_qV=${_Msh_qV//$CC1C/'\''${CC1C}'\''}
			_Msh_qV=${_Msh_qV//$CC1D/'\''${CC1D}'\''}
			_Msh_qV=${_Msh_qV//$CC1E/'\''${CC1E}'\''}
			_Msh_qV=${_Msh_qV//$CC1F/'\''${CC1F}'\''}
			_Msh_qV=${_Msh_qV//$CC7F/'\''${CC7F}'\''} ;;
		esac
		_Msh_qV_VAL=\"${_Msh_qV//\"/\\\"}\"
	}'
else
	# Replacing arbitrary characters with POSIX parameter substitutions is a
	# challenge. Use the algorithm from replacein() in the var/string module.
	_Msh_qV_R() {
		case ${_Msh_qV} in
		( *"$1"* )
			_Msh_qV_VAL=
			while case ${_Msh_qV} in ( *"$1"* ) ;; ( * ) ! : ;; esac; do
				_Msh_qV_VAL=${_Msh_qV_VAL}${_Msh_qV%%"$1"*}$2
				_Msh_qV=${_Msh_qV#*"$1"}
			done
			_Msh_qV=${_Msh_qV_VAL}${_Msh_qV} ;;
		esac
	}
	if thisshellhas ROFUNC; then
		readonly -f _Msh_qV_R
	fi
	_Msh_qV_dblQuote() {
		_Msh_qV=${_Msh_qV_VAL}
		_Msh_qV_R \\ \\\\
		_Msh_qV_R \" \\\"
		_Msh_qV_R \$ \\\$
		_Msh_qV_R \` \\\`
		case ${_Msh_qV_VAL} in
		( *[$CONTROLCHARS]* )
			_Msh_qV_R "$CC01" \${CC01}
			_Msh_qV_R "$CC02" \${CC02}
			_Msh_qV_R "$CC03" \${CC03}
			_Msh_qV_R "$CC04" \${CC04}
			_Msh_qV_R "$CC05" \${CC05}
			_Msh_qV_R "$CC06" \${CC06}
			_Msh_qV_R "$CC07" \${CCa}
			_Msh_qV_R "$CC08" \${CCb}
			_Msh_qV_R "$CC09" \${CCt}
			_Msh_qV_R "$CC0A" \${CCn}
			_Msh_qV_R "$CC0B" \${CCv}
			_Msh_qV_R "$CC0C" \${CCf}
			_Msh_qV_R "$CC0D" \${CCr}
			_Msh_qV_R "$CC0E" \${CC0E}
			_Msh_qV_R "$CC0F" \${CC0F}
			_Msh_qV_R "$CC10" \${CC10}
			_Msh_qV_R "$CC11" \${CC11}
			_Msh_qV_R "$CC12" \${CC12}
			_Msh_qV_R "$CC13" \${CC13}
			_Msh_qV_R "$CC14" \${CC14}
			_Msh_qV_R "$CC15" \${CC15}
			_Msh_qV_R "$CC16" \${CC16}
			_Msh_qV_R "$CC17" \${CC17}
			_Msh_qV_R "$CC18" \${CC18}
			_Msh_qV_R "$CC19" \${CC19}
			_Msh_qV_R "$CC1A" \${CC1A}
			_Msh_qV_R "$CC1B" \${CCe}
			_Msh_qV_R "$CC1C" \${CC1C}
			_Msh_qV_R "$CC1D" \${CC1D}
			_Msh_qV_R "$CC1E" \${CC1E}
			_Msh_qV_R "$CC1F" \${CC1F}
			_Msh_qV_R "$CC7F" \${CC7F} ;;
		esac
		_Msh_qV_VAL=\"${_Msh_qV}\"
	}
fi

# Main shellquote function.
shellquote() {
	_Msh_qV_ERR=4
	_Msh_qV_f=
	_Msh_qV_P=
	for _Msh_qV_N do
		case ${_Msh_qV_N} in
		([+-]*)	_Msh_qV_ERR=4
			case ${_Msh_qV_N} in
			( -f )		_Msh_qV_f=f ;;
			( +f )		_Msh_qV_f= ;;
			( -P )		_Msh_qV_P=P ;;
			( +P )		_Msh_qV_P= ;;
			( -fP | -Pf )	_Msh_qV_f=f; _Msh_qV_P=P ;;
			( +fP | +Pf )	_Msh_qV_f=; _Msh_qV_P= ;;
			( * )		_Msh_qV_ERR=3; break ;;
			esac
			continue ;;
		( *=* )	# Assignment argument
			_Msh_qV_VAL=${_Msh_qV_N#*=}
			_Msh_qV_N=${_Msh_qV_N%%=*}
			case ${_Msh_qV_N} in
			( "" | [0123456789]* | *[!"$ASCIIALNUM"_]* )
				_Msh_qV_ERR=2
				break ;;
			esac ;;
		( "" | [0123456789]* | *[!"$ASCIIALNUM"_]* )
			_Msh_qV_ERR=2
			break ;;
		( * )	! isset "${_Msh_qV_N}" && _Msh_qV_ERR=1 && break
			eval "_Msh_qV_VAL=\${${_Msh_qV_N}}" ;;
		esac
		_Msh_qV_ERR=0

		# Determine quoting method based on options (f, P) and value, trying
		# to reduce exponential string growth when doing repeated quoting.
		case ${_Msh_qV_f}${_Msh_qV_P},${_Msh_qV_VAL} in	 # BUG_ISSETLOOP compat: don't use ${_Msh_qV_f+f}, etc.

		(  ,'[' |  ,']' |  ,'[[' |  ,']]' |  ,'{' |  ,'}' |  ,'{}' \
		| P,'[' | P,']' | P,'[[' | P,']]' | P,'{' | P,'}' | P,'{}' )
			# Unless -f was given, don't bother quoting these. They are used unquoted in
			# shell scripts all the time, and are only unsafe if part of larger strings.
			;;

		( , | f, | fP, )
			# Quote empties.
			_Msh_qV_VAL="''" ;;

		( ,[!$CONTROLCHARS$SHELLSAFECHARS] | P,[!$CONTROLCHARS$SHELLSAFECHARS] )
			# No -f, a single non-ctrl, non-shellsafe char: backslash-escape.
			_Msh_qV_VAL=\\${_Msh_qV_VAL} ;;

		( ,\\[!$CONTROLCHARS$SHELLSAFECHARS] | P,\\[!$CONTROLCHARS$SHELLSAFECHARS] )
			# No -f, a single backslash-escaped non-ctrl, non-sellsafe char: double backslash-escape.
			_Msh_qV_VAL=\\\\${_Msh_qV_VAL} ;;

		( ,*[$CONTROLCHARS]* | f,*[$CONTROLCHARS]* )
			# No -P, some control char(s): double-quote to guarantee a printable one-line quoted string.
			_Msh_qV_dblQuote ;;

		( P,*[!$SHELLSAFECHARS]* | fP,* | *'\\'*'\\'*'\\'*'\\'*'\\'*'\\'*'\\'*'\\'* )
			# Either -P, or dblQuote would cause too much backslash growth: use mixed single/bksl quoting.
			_Msh_qV_sngQuote ;;

		( *[!$SHELLSAFECHARS]* | f,* )
			# Otherwise, if -f given or any non-shellsafe chars, double-quote.
			_Msh_qV_dblQuote ;;
		esac

		eval "${_Msh_qV_N}=\${_Msh_qV_VAL}"
	done

	case ${_Msh_qV_ERR} in
	( 0 )	unset -v _Msh_qV _Msh_qV_C _Msh_qV_VAL _Msh_qV_f _Msh_qV_P _Msh_qV_N _Msh_qV_ERR ;;
	( 1 )	die "shellquote: unset variable: ${_Msh_qV_N}" ;;
	( 2 )	die "shellquote: invalid variable name: ${_Msh_qV_N}" ;;
	( 3 )	die "shellquote: invalid option: ${_Msh_qV_N}" ;;
	( 4 )	die "shellquote: expected variable(s) to quote" ;;
	( * )	die "shellquote: internal error (${_Msh_qV_ERR})" ;;
	esac
}

# Shell-quote all the positional parameters in-place.
alias shellquoteparams='{ '\
'for _Msh_Q do'\
' shift && shellquote _Msh_Q && set -- "$@" "${_Msh_Q}" || die; '\
'done; '\
'unset -v _Msh_Q; }'

if thisshellhas ROFUNC; then
	readonly -f shellquote _Msh_qV_dblQuote _Msh_qV_sngQuote _Msh_qV_sngQuote_do1fld
fi
