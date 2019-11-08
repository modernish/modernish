#! /module/for/moderni/sh
\command unalias source _Msh_doSource 2>/dev/null

# sys/cmd/source: enhanced dot scripts
#
# 'source' as in zsh and bash, with optional positional parameters, now also
# available to (d)ash, yash and *ksh*. If extra arguments are given, they
# are passed to the dot script as local positional parameters as in a shell
# function; if not, the dot script inherits the calling environment's
# positional parameters (unlike a shell function).
#
# In pure POSIX shells, '.' cannot pass extra arguments, and dot scripts
# always inherit the caller's positional parameters; this can be worked
# around with a shell function. However, this is implementation-dependent;
# in bash, *ksh* and zsh, '.' does pass the parameters. Modernish scripts
# should use 'source' instead of '.' for consistent functionality.

thisshellhas source && return

command alias source='_Msh_doSource "$#" "$@"'
_Msh_doSource() {
	let "$# > ( $1 + 1 )" || die "source: need at least 1 argument, got 0"
	eval "_Msh_source_S=\${$(( $1 + 2 ))}"

	if let "$# > ( $1 + 2 )"; then
		# extra arguments were given; discard the number of caller's positional parameters, the
		# caller's positional parameters themselves, and the argument indicating the dot script
		shift "$(( $1 + 2 ))"
	else
		# no extra arguments were given; keep caller's positional parameters, but remove the number
		# of them (first parameter) and the argument indicating the dot script (last parameter)
		_Msh_source_P=''
		_Msh_source_i=1
		while let "(_Msh_source_i+=1) < $#"; do
			_Msh_source_P="${_Msh_source_P} \"\${${_Msh_source_i}}\""
		done
		eval "set -- ${_Msh_source_P}"
		unset -v _Msh_source_P _Msh_source_i
	fi

	# Unlike '.', find the dot script in the current directory, not just in $PATH.
	case ${_Msh_source_S} in
	( */* ) ;;
	( * )	if is -L reg "${_Msh_source_S}"; then
			_Msh_source_S=./${_Msh_source_S}
		fi ;;
	esac

	. "${_Msh_source_S}"
	eval "unset -v _Msh_source_S; return $?"
}

if thisshellhas ROFUNC; then
	readonly -f _Msh_doSource
fi
