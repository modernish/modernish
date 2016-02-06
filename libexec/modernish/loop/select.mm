#! /module/for/moderni/sh
# An alias + internal function pair for a ksh/bash/zsh-style 'select' loop.
# This aims to be a perfect replica of the 'select' builtin in these shells,
# making it truly cross-platform.
#
# BUG:	'select' is not a true shell keyword, but an alias for two commands.
#	This makes it impossible to pipe data directly into a 'select' loop.
#	Workaround: enclose the entire loop in { braces; }.
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


# If we already have 'select', no need to reimplement it.
# (In ksh, it's not even possible.)
if thisshellhas select; then
	return
fi

# The alias can work because aliases are expanded even before shell keywords
# like 'while' are parsed. Pass on the number of positional parameters plus
# the positional parameters themselves in case "in <words>" is not given,
# in a way that is compatible with BUG_UPP.
alias select='REPLY='' && while _Msh_doSelect "$#" "${@:-}"'

# In the main function, we do still need to prefix the local variables with
# the reserved _Msh_ namespace prefix, because any name of a variable in
# which to store the reply value could be given as a parameter.
_Msh_doSelect() {
	push _Msh_pop _Msh_argc _Msh_V _Msh_val
	_Msh_pop='pop _Msh_pop _Msh_argc _Msh_V _Msh_val'

	_Msh_argc="$1"
	if eq "$1" 0; then
		shift 2  # BUG_UPP workaround
	else
		shift
	fi

	eval "_Msh_V=\${$((_Msh_argc+1)):-}"

	case "${_Msh_V}" in
	( '' )
		die "select: syntax error: variable name expected" || return ;;
	( [0123456789]* | *[!${ASCIIALNUM}_]* )
		die "select: invalid variable name: ${_Msh_V}" || return ;;
	esac

	if ge "$#" _Msh_argc+2; then
		eval "_Msh_val=\"\${$((_Msh_argc+2))}\""
		if same "${_Msh_val}" 'in'; then
			# discard caller's positional parameters
			shift "$((_Msh_argc+2))"
			_Msh_argc="$#"
		else
			die "select: syntax error: 'in' expected${_Msh_val+:, got \'$_Msh_val\'}"  || return
		fi
	fi

	gt "${_Msh_argc}" 0 || return

	if empty "$REPLY"; then
		_Msh_doSelect_printMenu "${_Msh_argc}" "$@"
	fi

	printf '%s' "${PS3-#? }"
	IFS="$WHITESPACE" read REPLY || { eval "${_Msh_pop}"; return 1; }

	while empty "$REPLY"; do
		_Msh_doSelect_printMenu "${_Msh_argc}" "$@"
		printf '%s' "${PS3-#? }"
		IFS="$WHITESPACE" read REPLY || { eval "${_Msh_pop}"; return 1; }
	done

	if thisshellhas BUG_READWHSP; then
		# trim left-hand IFS whitespace
		REPLY="${REPLY#"${REPLY%%[!"$WHITESPACE"]*}"}"	# "
	fi

	if isint "$REPLY" && gt REPLY 0 && le REPLY _Msh_argc; then
		eval "${_Msh_V}=\${$REPLY}"
	else
		eval "${_Msh_V}=''"
	fi

	eval "${_Msh_pop}"
}

# Internal function for formatting and printing the 'select' menu.
# Not for public use.
#
# Bug: even shells without BUG_MULTIBYTE can't deal with the UTF-8-MAC
# insanity ("decomposed UTF-8") in which the Mac encodes filenames. Nor do
# the Mac APIs translate them back to proper UTF-8. So, directly working
# with filenames, such as "select varname in *", will mess up column display
# on the Mac if your filenames contain non-ASCII characters. (This is true
# for everything, including native 'select' in bash/ksh/zsh, and even the
# /bin/ls that ships with the Mac! So at least we're bug-compatible with
# real 'select' implementations...)

if not thisshellhas BUG_MULTIBYTE; then

# Version for correct ${#varname} (measuring length in characters, not
# bytes, on shells with variable-width character sets).

	_Msh_doSelect_printMenu() {
		push argc maxlen columns offset i j val
		argc="$1"; shift
		maxlen=0

		for val do
			if gt "${#val}" maxlen; then
				maxlen="${#val}"
			fi
		done
		inc maxlen "${#argc}+2"
		columns="$(( ${COLUMNS:-80} / (maxlen + 2) ))"
		if lt columns 1; then columns=1; fi
		offset="$(( argc / columns + 1 ))"
		#print "DEBUG: maxlen=$maxlen columns=$columns offset=$offset"

		i=1
		while le i offset; do
			j="$i"
			while le j argc; do
				eval "val=\"\${${j}}\""
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

	# First check if 'wc -m' functions correctly.
	_Msh_ctest="$(export LC_ALL=nl_NL.UTF-8; printf 'mis\303\250ri\303\253n' | wc -m)"
	if not { isint "${_Msh_ctest}" && eq _Msh_ctest 8; }; then
		print "Command 'wc -m' does not correctly measure length in characters." 1>&2
		return 2
	fi

	_Msh_doSelect_printMenu() {
		push argc maxlen columns offset i j val
		argc="$1"; shift
		maxlen=0

		for val do
			len="$(printf '%s' "${val}${argc}xx" | wc -m)"
			if gt len maxlen; then
				maxlen="$len"
			fi
		done
		columns="$(( ${COLUMNS:-80} / (maxlen + 2) ))"
		if lt columns 1; then columns=1; fi
		offset="$(( argc / columns + 1 ))"
		#print "DEBUG: maxlen=$maxlen columns=$columns offset=$offset"

		i=1
		while le i offset; do
			j="$i"
			while le j argc; do
				eval "val=\"\${${j}}\""
				len="$(printf '%s%d' "${val}" "${argc}" | wc -m)"
				printf "%${#argc}d) %s%$((maxlen - len))c" "$j" "$val" ' '
				inc j offset
			done
			printf '\n'
			inc i
		done

		pop argc maxlen columns offset i j val
	}

fi
