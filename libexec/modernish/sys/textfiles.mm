#! /module/for/moderni/sh

# Functions for working with text files.
# TODO: analogous binary.mm functions that allow escaped binary data
# in format suitable for interpretation by 'printf'.


# readf <varname> [ <file> ... ]: concatenate the text file(s) and/or
# standard input into the variable until EOF is reached. A <file> of '-'
# represents standard input. In the absence of <file> arguments, standard
# input is read.
# Unlike with command substitution, only the last linefeed is stripped.
# Text files with no final linefeed (which is invalid) are treated as if they
# have one final linefeed character which is then stripped.
# Text files are always supposed to end in a linefeed, so simply
#	print "$var" > file
#	(which is the same as: printf '%s\n' "$var" > file)
# will correctly write the file back to disk.
readf() {
	ge "$#" 1 || die "readf: incorrect number of arguments (was $#, must be at least 1)" || return
	case "$1" in
	( '' | [0123456789]* | *[!${ASCIIALNUM}_]* )
		die "readf: invalid variable name: $1" || return ;;
	esac
	eval "$1=''"
	_Msh_readf_C="
		while IFS='' read -r _Msh_readf_L; do
			$1=\"\${$1:+\${$1}\${CCn}}\${_Msh_readf_L}\"
		done
		empty \"\${_Msh_readf_L}\" || $1=\"\${$1:+\${$1}\${CCn}}\${_Msh_readf_L}\"
	"
	if gt "$#" 1; then
		shift
		while gt "$#" 0; do
			if same "$1" '-'; then
				eval "${_Msh_readf_C}"
			else
				not isdir -L "$1" || die "readf: $1: Is a directory" || return
				eval "${_Msh_readf_C}" < "$1" || die "readf: failed to read file \"$1\"" || return
			fi
			shift
		done
	else
		eval "${_Msh_readf_C}"
	fi
	unset -v _Msh_readf_C _Msh_readf_L
}


# kitten is cat without launching any external process.
# Much slower than cat for big files, but much faster for tiny ones.
# Limitation: Text files only. Incompatible with binary files.
# Use cases:
# -	Allows showing here-documents with less overhead.
# -	Faster reading / conkittenenating / copying of small text files.
# Usage: just like cat. '-' is supported. No options are supported.
if thisshellhas printf; then
	# Version for shells with 'printf' built in.
	kitten() {
		if gt "$#" 0; then
			while gt "$#" 0; do
				if same "$1" '-'; then
					kitten
				else
					not isdir -L "$1" || die "kitten: $1: Is a directory" || return
					kitten < "$1" || return
				fi
				shift
			done
			return
		fi
		while IFS='' read -r _Msh_kittenL; do
			printf '%s\n' "${_Msh_kittenL}"
		done
		unset -v _Msh_kittenL
	}
elif thisshellhas print; then
	# Version for shells without 'printf' built in but with
	# proprietary 'print' builtin (i.e. pdksh, mksh).
	kitten() {
		if gt "$#" 0; then
			while gt "$#" 0; do
				if same "$1" '-'; then
					kitten
				else
					not isdir -L "$1" || die "kitten: $1: Is a directory" || return
					kitten < "$1" || return
				fi
				shift
			done
			return
		fi
		while IFS='' read -r _Msh_kittenL; do
			command print -r -- "${_Msh_kittenL}"
		done
		unset -v _Msh_kittenL
	}
else
	# I don't think there is any shell that has neither 'printf' nor 'print' but you never know.
	# For those, if they exist, just using 'cat' would be the most efficient option.
	# (Unfortunately, the 'echo' builtin can't be used for arbitrary data.)
	kitten() {
		cat "$@"
	}
fi

# nettik is tac without launching any external process.
# Output each file in reverse order, last line first. See kitten().
nettik() {
	if gt "$#" 0; then
		while gt "$#" 0; do
			if same "$1" '-'; then
				nettik
			else
				not isdir -L "$1" || die "nettik: $1: Is a directory" || return
				nettik < "$1" || return
			fi
			shift
		done
		return
	fi
	_Msh_nettikF=''
	while IFS='' read -r _Msh_nettikL; do
		_Msh_nettikF="${_Msh_nettikL}${CCn}${_Msh_nettikF}"
	done
	printf '%s' "${_Msh_nettikF}"
	unset -v _Msh_nettikL _Msh_nettikF
}
