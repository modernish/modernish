#! moderni/sh

# modernish module:

# readfile <file> <var>: read an entire file into <var> without launching a subshell
# writefile [ -f ] <file> <args>: write the contents of <args> into file, clobbering if -f is given

# TODO: analogous files/binary.mm functions that allow escaped binary data
# See: http://www.etalabs.net/sh_tricks.html "Reading input byte-by-byte"

readfile() {
	{
		IFS='' read -r VAL \
		&& while IFS='' read -r _Msh_files_line; do
			VAL="$VAL
$_Msh_files_line"
		done && unset _Msh_files_line
	} < "$1" \
	|| die "readfile: failed to read file \"$1\""
}

writefile() {
	printf '%s\n' "$2" >| "$1"
}

# kitten is cat without launching any external process.
# Much slower than cat for big files, but much faster for tiny ones.
# Limitation: Text files only. Incompatible with binary files.
# Use cases:
# -	Allows showing here-documents with much less overhead.
# -	Faster reading / con-kitten-enating / copying of small text files.
# Usage: just like cat. '-' is supported. No options are supported.
kitten() {
	if [ $# -gt 0 ]; then
		while [ $# -gt 0 ]; do
			if [ "$1" = '-' ]; then
				kitten
			else
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

