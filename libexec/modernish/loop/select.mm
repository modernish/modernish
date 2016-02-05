#! /module/for/moderni/sh
# An alias + internal function pair for a ksh/bash/zsh-style 'select' loop.
# This aims to be a perfect replica of the 'select' builtin in these shells,
# making it truly cross-platform.

# If we already have 'select', no need to reimplement it.
# (In ksh, it's not even possible.)
if thisshellhas select; then
	return
fi

# We can safely use non-standard 'local' here because in fact every current
# shell except AT&T's ksh has this keyword, whereas ksh has 'select' built
# in so it doesn't need this function.
# Do a check anyway, just to make sure.
if not isset MSH_HASLOCAL; then
	die "select: This module requires the 'local' shell keyword." || return
fi

# The alias can work because aliases are expanded even before shell keywords
# like 'while' are parsed. Pass on the number of positional parameters plus
# the positional parameters themselves in case "in <words>" is not given.
#
# (Must use "${@:-}" instead of "$@", adding a default empty dummy argument,
# because some shells, when 'set -u' is used, error out on "$@" if there are
# no positional parameters.)
alias select='_Msh_select_printMenu=y && while _Msh_doSelect $# "${@:-}"'

# In the main function, we do still need to prefix the local variables with
# the reserved _Msh_ namespace prefix, because any name of a variable in
# which to store the reply value could be given as a parameter.
_Msh_doSelect() {
	local _Msh_argc _Msh_i _Msh_varname _Msh_val

	_Msh_argc="$1"
	if eq "$1" 0; then
		shift 2  # also get rid of empty dummy argument
	else
		shift
	fi

	eval "_Msh_varname=\${$((_Msh_argc+1)):-}"

	case "${_Msh_varname}" in
	( '' )
		die "select: syntax error: variable name expected" || return ;;
	( [!a-zA-Z_]* | *[!a-zA-Z0-9_]* )
		die "select: invalid variable name: ${_Msh_varname}" || return ;;
	esac

	if ge $# $((_Msh_argc+2)); then
		eval "_Msh_val=\"\${$((_Msh_argc+2))}\""
		if same "${_Msh_val}" 'in'; then
			# discard caller's positional parameters
			shift $((_Msh_argc+2))
			_Msh_argc=$#
		else
			die "select: syntax error: 'in' expected, got '${_Msh_val}'"  || return
		fi
	fi

	gt ${_Msh_argc} 0 || return

	if isset _Msh_select_printMenu; then
		unset -v _Msh_select_printMenu
		_Msh_doSelect_printMenu "$@"
	fi

	printf '%s' "${PS3-#? }"
	IFS="$WHITESPACE" read _Msh_i || return

	while empty "${_Msh_i}"; do
		_Msh_doSelect_printMenu "$@"
		printf '%s' "${PS3-#? }"
		IFS="$WHITESPACE" read _Msh_i || return
	done

	if isint "${_Msh_i}" && gt "${_Msh_i}" 0 && le "${_Msh_i}" "${_Msh_argc}"; then
		eval "${_Msh_varname}=\${${_Msh_i}}"
	else
		eval "${_Msh_varname}=''"
	fi
}

# TODO: multicolumn layout if there are many options, like in bash/ksh/zsh
_Msh_doSelect_printMenu() {
	local i=0 val
	while lt ${i} ${_Msh_argc} && inc i; do
		eval "val=\"\${${i}}\""
		printf "%${##}d) %s\n" "${i}" "${val}"
	done
}
