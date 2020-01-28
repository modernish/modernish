#! /shell/capability/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# DOTARG: Arguments to dot scripts become positional parameters local to the
# dot script, as if they are shell functions.

set --	# clear PPs
if command . /dev/null one two 2>/dev/null; then
	# test if extra arguments are ignored
	command . "$MSH_AUX/cap/DOTARG.sh" one two
	return	# with status of DOTARG.sh
else
	# extra arguments are an error (yash -o posix)
	return 1
fi
