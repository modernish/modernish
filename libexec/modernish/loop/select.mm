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

# If we already have 'select', no need to reimplement it. In fact, it's not
# even possible, as 'select' is a reserved word like 'for' and 'while'.
if thisshellhas select; then
	# wrap select loop in 'eval' to avoid parsing error on shells without 'select'
	if not identic 'X' "$(print X | eval 'select r in 1 2 3; do print "$REPLY"; break; done' 2>/dev/null)"; then
		print "loop/select: This shell's 'select' built-in command has a bug where input that" \
		      "             is not a menu item is not stored in the REPLY variable as it should" \
		      "             be. Unfortunately, replacing it with modernish's own implementation" \
		      "             is impossible, because 'select' is a shell keyword (reserved word)."
		if isset KSH_VERSION && ematch "$KSH_VERSION" '^@\(#\)(MIRBSD|LEGACY) KSH '; then
			print "             Upgrade mksh to version R50 2015/04/19 or later to fix this." \
			      "             (Current version: $KSH_VERSION)"
		else
			print "             Check that your shell is the latest version or use another."
		fi
		return 1
	fi
	return 0
fi

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

	if ge "$#" _Msh_argc+2; then
		if eval "identic \"\${$((_Msh_argc+2))}\" 'in'"; then
			# discard caller's positional parameters
			shift "$((_Msh_argc+2))"
			_Msh_argc=$#
		else
			shift "${_Msh_argc}"
			die "select: syntax error: 'in' expected${2+:, got \'$2\'}"  || return
		fi
	fi

	gt _Msh_argc 0 || return

	if empty "$REPLY"; then
		_Msh_doSelect_printMenu "${_Msh_argc}" "$@"
	fi
	printf '%s' "${PS3-#? }"
	IFS=$WHITESPACE read -r REPLY || { pop _Msh_argc _Msh_V; return 1; }

	while empty "$REPLY"; do
		_Msh_doSelect_printMenu "${_Msh_argc}" "$@"
		printf '%s' "${PS3-#? }"
		IFS=$WHITESPACE read -r REPLY || { pop _Msh_argc _Msh_V; return 1; }
	done

	if thisshellhas BUG_READTWHSP; then
		REPLY=${REPLY%"${REPLY##*[!$WHITESPACE]}"}				# "
	fi

	if isint "$REPLY" && gt REPLY 0 && le REPLY _Msh_argc; then
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
	_Msh_ctest=$(export LC_ALL=nl_NL.UTF-8; printf 'mis\303\250ri\303\253n' | wc -m)
	if isint "${_Msh_ctest}" && eq _Msh_ctest 8; then
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
			if gt "${#val}" maxlen; then
				maxlen=${#val}
			fi
		done
		inc maxlen "${#argc}+2"
		columns=$(( ${COLUMNS:-80} / (maxlen + 2) ))
		if lt columns 1; then columns=1; fi
		offset=$(( argc / columns ))
		until ge columns\*offset argc; do
			inc offset
		done
		#print "DEBUG: maxlen=$maxlen columns=$columns offset=$offset"

		i=1
		while le i offset; do
			j=$i
			while le j argc; do
				eval "val=\${${j}}"
				printf "%${#argc}d) %s%$((maxlen - ${#val} - ${#argc}))c" "$j" "$val" ' '
				inc j offset
			done
			printf '\n'
			inc i
		done

		pop argc maxlen columns offset i j val
	}

else

# Workaround version for ${#varname} measuring length in bytes, not characters.
# Uses 'wc -m' instead, at the expense of launching subshells and external processes.

	_Msh_doSelect_printMenu() {
		push argc len maxlen columns offset i j val
		argc=$1; shift
		maxlen=0

		for val do
			len=$(printf '%s' "${val}${argc}xx" | wc -m)
			if gt len maxlen; then
				maxlen=$len
			fi
		done
		columns=$(( ${COLUMNS:-80} / (maxlen + 2) ))
		if lt columns 1; then columns=1; fi
		offset=$(( argc / columns ))
		until ge columns\*offset argc; do
			inc offset
		done
		#print "DEBUG: maxlen=$maxlen columns=$columns offset=$offset"

		i=1
		while le i offset; do
			j=$i
			while le j argc; do
				eval "val=\${${j}}"
				len=$(printf '%s%d' "${val}" "${argc}" | wc -m)
				printf "%${#argc}d) %s%$((maxlen - len))c" "$j" "$val" ' '
				inc j offset
			done
			printf '\n'
			inc i
		done

		pop argc len maxlen columns offset i j val
	}

fi
