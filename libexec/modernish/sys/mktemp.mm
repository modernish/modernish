#! /module/for/moderni/sh

#_Msh_mktemp=$(command -v mktemp) >| /dev/null
#if so; then
#	# Function to enforce cross-platform compatible options.
#	mktemp() {
#	}
#else

# Not yet written:
#use sys/readlink
#use sys/getfilemode

# Cross-platform "mktemp" replacement. Tries to be as safe and atomic as possible.
mktemp() {
	isdir -L /tmp && canwrite /tmp || die "/tmp directory inaccessible" || return
	# TODO: if directory is symlink, read link and use physical path (else, vuln to symlink attacks)
	# TODO: check directory for safe permissions (either sticky bit set, or user writable only)

	# Find a suffix based on $RANDOM or (if we don't have $RANDOM) based on $$.
	_Msh_mktemp_id="${RANDOM-$$}"
	until ( umask 177 && set -C && exec > "/tmp/file.${_Msh_mktemp_id}" ); do
		inc _Msh_mktemp_id "${RANDOM-$$}"
	done 2>| /dev/null
	print "/tmp/file.${_Msh_mktemp_id}"
}
	