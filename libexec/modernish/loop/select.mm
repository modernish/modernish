#! /module/for/moderni/sh
# An alias + internal function pair for a ksh/bash/zsh-style 'select' loop.
# This aims to be a perfect replica of the 'select' loop in these shells,
# making it truly cross-platform. The modernish reimplementation is only
# loaded in shells that don't have it built in.
#
# BUG: 'select' is not a true shell keyword, but an alias for two commands.
# This means two things:
# 1.	Even if 'in arg ...' is omitted so that the positional parameters
#	are used, the ';' before 'do' is still mandatory. So instead of
#		select NAME do COMMANDS; done
#	you have to say
#		select NAME; do COMMANDS; done
#	Thankfully this is also accepted by all the native implementations,
#	so the variant with the extra ';' is compatible with everything.
# 2.	You can't pipe data directly into a 'select' loop.
#	Workaround: enclose the entire loop in braces, like this:
#	somecommand | { select NAME in STUFF; do COMMANDS; done; }
# Also note:
# - If a user presses Ctrl-D (EOF), native 'select' in bash and *ksh
#   exits the loop with status 1; modernish exits with status 0 because
#   this is internally a 'while' loop. (zsh also exits with status 0.)
# - If a user presses Ctrl-D (EOF), native 'select' on zsh does not clear
#   the REPLY variable, so it will contain whatever it did before 'select'.
#   But modernish automatically clears it because it uses 'read'. All other
#   native implementations also clear it.
#
# Citing from 'help select' in bash 3.2.57:
#	select: select NAME [in WORDS ... ;] do COMMANDS; done
#	    The WORDS are expanded, generating a list of words.  The
#	    set of expanded words is printed on the standard error, each
#	    preceded by a number.  If `in WORDS' is not present, `in "$@"'
#	    is assumed.  The PS3 prompt is then displayed and a line read
#	    from the standard input.  If the line consists of the number
#	    corresponding to one of the displayed words, then NAME is set
#	    to that word.  If the line is empty, WORDS and the prompt are
#	    redisplayed.  If EOF is read, the command completes.  Any other
#	    value read causes NAME to be set to null.  The line read is saved
#	    in the variable REPLY.  COMMANDS are executed after each selection
#	    until a break command is executed.
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

unset -v _Msh_select_wSELECTRPL _Msh_select_wSELECTEOF _Msh_select_err
while let "$#"; do
	case "$1" in
	( -w )
		# declare that the program will work around a shell bug affecting 'use loop/select'
		let "$# >= 2" || die "safe.mm: option requires argument: -w" || return
		case "$2" in
		( BUG_SELECTRPL ) _Msh_select_wSELECTRPL=y ;;
		( BUG_SELECTEOF ) _Msh_select_wSELECTEOF=y ;;
		esac
		shift
		;;
	( -??* )
		# if option and option-argument are 1 argument, split them
		_Msh_select_tmp=$1
		shift
		if thisshellhas BUG_UPP; then	# must check this so we don't hit BUG_PARONEARG on bash
			set -- "${_Msh_select_tmp%"${_Msh_select_tmp#-?}"}" "${_Msh_select_tmp#-?}" ${1+"$@"}			# "
		else
			set -- "${_Msh_select_tmp%"${_Msh_select_tmp#-?}"}" "${_Msh_select_tmp#-?}" "$@"			# "
		fi
		unset -v _Msh_select_tmp
		continue
		;;
	( * )
		putln "loop/select: invalid option: $1"
		return 1
		;;
	esac
	shift
done

# If we already have 'select', no need to reimplement it. In fact, it's not
# even possible, as 'select' is a reserved word like 'for' and 'while'.
if thisshellhas --rw=select; then
	# However, do check for certain bugs in native 'select' implementations:

	# Check for a big bug in 'select' on older mksh: the REPLY variable is not filled.
	if not isset _Msh_select_wSELECTRPL && thisshellhas BUG_SELECTRPL; then
		putln "loop/select: BUG_SELECTRPL detected." \
		      "             This shell's native 'select' loop command has a bug where input that" \
		      "             is not a menu item is not stored in the REPLY variable as it should" \
		      "             be. Unfortunately, replacing it with modernish's own implementation" \
		      "             is impossible, because 'select' is a shell keyword (reserved word)."
		if isset KSH_VERSION && ematch "$KSH_VERSION" '^@\(#\)(MIRBSD|LEGACY) KSH '; then
			putln "             Upgrade mksh to version R50 2015/04/19 or later to fix this." \
			      "             (Current version: $KSH_VERSION)"
		else
			putln "             Check that your shell is the latest version or use another."
		fi
		putln "             To override this bug check, add -wBUG_SELECTRPL to 'use loop/select'" \
		      "             and make sure your script doesn't rely on the REPLY variable."
		_Msh_select_err=y
	fi

	# Check for a bug on zsh: REPLY is not emptied when exiting a 'select' loop with EOF (Ctrl+D).
	if not isset _Msh_select_wSELECTEOF && thisshellhas BUG_SELECTEOF; then
		putln "loop/select: BUG_SELECTEOF detected." \
		      "             This shell's native 'select' loop command has a bug where the REPLY" \
		      "             variable is not cleared if the user presses Ctrl-D to exit the loop." \
		      "             This means you can't test for this by testing the emptiness of" \
		      "             \$REPLY unless you empty REPLY yourself before entering the loop."
		if isset ZSH_VERSION; then
			putln "             Upgrade zsh to version 5.3 or later to fix this." \
			      "             (Current version: $ZSH_VERSION)"
		else
			putln "             Check that your shell is the latest version or use another."
		fi
		putln "             To override this bug check, add -wBUG_SELECTEOF to 'use loop/select'" \
		      "             and make sure your script empties REPLY before executing 'select'."
		_Msh_select_err=y
	fi

	if isset _Msh_select_err; then
		unset -v _Msh_select_err _Msh_select_wSELECTRPL _Msh_select_wSELECTEOF
		return 1
	else
		# We're happy with our native 'select'.
		unset -v _Msh_select_wSELECTRPL _Msh_select_wSELECTEOF
		return 0
	fi
fi

unset -v _Msh_select_wSELECTRPL _Msh_select_wSELECTEOF

# Hardened 'printf'.
harden -p -f _Msh_select_prf printf

# The alias can work because aliases are expanded even before shell keywords
# like 'while' are parsed. Pass on the number of positional parameters plus
# the positional parameters themselves in case "in <words>" is not given.
if thisshellhas BUG_UPP; then
	alias select='REPLY='' && while _Msh_doSelect "$#" ${1+"$@"}'
else
	alias select='REPLY='' && while _Msh_doSelect "$#" "$@"'
fi
# In the main function, we do still need to prefix the local variables with
# the reserved _Msh_ namespace prefix, because any name of a variable in
# which to store the reply value could be given as a parameter.
_Msh_doSelect() {
	push _Msh_argc _Msh_V

	_Msh_argc=$1
	shift

	eval "_Msh_V=\${$((_Msh_argc+1)):-}"
	not empty "${_Msh_V}" || die "select: syntax error: variable name expected" || return
	isvarname "${_Msh_V}" || die "select: invalid variable name: ${_Msh_V}" || return

	if let "$# >= _Msh_argc+2"; then
		if eval "identic \"\${$((_Msh_argc+2))}\" 'in'"; then
			# discard caller's positional parameters
			shift "$((_Msh_argc+2))"
			_Msh_argc=$#
		else
			shift "${_Msh_argc}"
			die "select: syntax error: 'in' expected${2+:, got \'$2\'}"  || return
		fi
	fi

	let "_Msh_argc > 0" || return

	if empty "$REPLY"; then
		_Msh_doSelect_printMenu "${_Msh_argc}" "$@"
	fi
	put "${PS3-#? }"
	IFS=$WHITESPACE read -r REPLY || { pop _Msh_argc _Msh_V; return 1; }

	while empty "$REPLY"; do
		_Msh_doSelect_printMenu "${_Msh_argc}" "$@"
		put "${PS3-#? }"
		IFS=$WHITESPACE read -r REPLY || { pop _Msh_argc _Msh_V; return 1; }
	done

	if thisshellhas BUG_READTWHSP; then
		REPLY=${REPLY%"${REPLY##*[!"$WHITESPACE"]}"}				# "
	fi

	if isint "$REPLY" && let "REPLY > 0 && REPLY <= _Msh_argc"; then
		eval "${_Msh_V}=\${$((REPLY))}"
	else
		eval "${_Msh_V}=''"
	fi

	pop _Msh_argc _Msh_V
}

# Internal function for formatting and printing the 'select' menu.
# Not for public use.
#
# Bug: even shells without BUG_MULTIBYTE can't deal with the UTF-8-MAC
# insanity ("decomposed UTF-8") in which the Mac encodes filenames. Nor do
# the Mac APIs translate them back to proper UTF-8. So, directly working
# with filenames, such as "select varname in *", will mess up column display
# on the Mac if your filenames contain non-ASCII characters. (This is true
# for everything, including 'select' in bash, *ksh* and zsh, and even the
# /bin/ls that ships with the Mac! So at least we're bug-compatible with
# native 'select' implementations...)

if not thisshellhas BUG_MULTIBYTE \
|| not {
	# test if 'wc -m' functions correctly; if not, don't bother to use it as a workaround
	# (for instance, OpenBSD is fscked if you use UTF-8; none of the standard utils work right)
	_Msh_ctest=$(export LC_ALL=nl_NL.UTF-8 "PATH=$DEFPATH"; _Msh_select_prf 'mis\303\250ri\303\253n' | wc -m)
	if isint "${_Msh_ctest}" && let "_Msh_ctest == 8"; then
		unset -v _Msh_ctest; true
	else
		unset -v _Msh_ctest; false
	fi
}; then

# Version for correct ${#varname} (measuring length in characters, not
# bytes, on shells with variable-width character sets).

	_Msh_doSelect_printMenu() {
		push argc maxlen columns offset i j val
		argc=$1; shift
		maxlen=0

		for val do
			if let "${#val} > maxlen"; then
				maxlen=${#val}
			fi
		done
		let "maxlen += (${#argc}+2)"
		columns=$(( ${COLUMNS:-80} / (maxlen + 2) ))
		if let "columns < 1"; then columns=1; fi
		offset=$(( argc / columns ))
		until let "columns*offset >= argc"; do
			let "offset += 1"
		done

		i=1
		while let "i <= offset"; do
			j=$i
			while let "j <= argc"; do
				eval "val=\${${j}}"
				_Msh_select_prf "%${#argc}d) %s%$((maxlen - ${#val} - ${#argc}))c" "$j" "$val" ' '
				let "j += offset"
			done
			putln
			let "i += 1"
		done

		pop argc maxlen columns offset i j val
	}

else

# Workaround version for ${#varname} measuring length in bytes, not characters.
# Uses 'wc -m' instead, at the expense of launching subshells and external processes.

	harden -p -f _Msh_doSelect_wc wc
	_Msh_doSelect_printMenu() {
		push argc len maxlen columns offset i j val
		argc=$1; shift
		maxlen=0

		for val do
			len=$(put "${val}${argc}xx" | _Msh_doSelect_wc -m)
			if let "len > maxlen"; then
				maxlen=$len
			fi
		done
		columns=$(( ${COLUMNS:-80} / (maxlen + 2) ))
		if let "columns < 1"; then columns=1; fi
		offset=$(( argc / columns ))
		until let "columns*offset >= argc"; do
			let "offset += 1"
		done

		i=1
		while let "i <= offset"; do
			j=$i
			while let "j <= argc"; do
				eval "val=\${${j}}"
				len=$(put "${val}${argc}" | _Msh_doSelect_wc -m)
				_Msh_select_prf "%${#argc}d) %s%$((maxlen - len))c" "$j" "$val" ' '
				let "j += offset"
			done
			putln
			let "i += 1"
		done

		pop argc len maxlen columns offset i j val
	}

fi

if thisshellhas ROFUNC; then
	readonly -f _Msh_select_prf _Msh_doSelect_wc _Msh_doSelect _Msh_doSelect_printMenu 2>/dev/null || :
fi
