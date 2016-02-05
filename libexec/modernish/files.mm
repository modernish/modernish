#! /bin/sh

# modernish module:

# readfile <file> <var>: read an entire file into <var> without launching a subshell
# writefile [ -f ] <file> <args>: write the contents of <args> into file, clobbering if -f is given

# TODO: analogous files/binary.mm functions that allow escaped binary data
# See: http://www.etalabs.net/sh_tricks.html "Reading input byte-by-byte"

readfile() {
	{
		IFS='' read -r VAL \
		&& while IFS='' read -r _msh_files_line; do
			VAL="$VAL
$_msh_files_line"
		done && unset _msh_files_line
	} < "$1" \
	|| die "readfile: failed to read file \"$1\""
}

writefile() {
	printf '%s\n' "$2" >| "$1"
}
