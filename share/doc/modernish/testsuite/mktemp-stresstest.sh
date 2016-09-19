#! /usr/bin/env modernish
use safe -w BUG_APPENDC -w BUG_UPP
use sys/base/mktemp
use sys/dir/countfiles
use loop/with

# Stress test for atomicity of modernish' "mktemp" implementation.
# Try to create many temp files in parallel (default 250).
# You might find the limits depend very much on the shell... having $RANDOM helps.
#
# This script deliberately uses weird characters (spaces, tabs, newlines)
# in the directory and file names to test for robustness on that, too.

# option -d to test creating directories
if gt $# 0 && identic $1 -d; then
	opt_dir=-d
	shift
else
	opt_dir=''	# empty removal will remove this from the mktemp command
fi

# location of directory for temp files
mydir=$(mktemp -d /tmp/mktemp\ test${CCn}directory.XXXXXX)

# the number of files to create in parallel
# (default 250, or indicate on command line)
num_files=${1:-250}

echo -n "PIDs are:"
with i=1 to $num_files; do
	mktemp -s $opt_dir $mydir/just${CCt}one\ test${CCn}file.XXXXXX &
	echo -n " $!"
done
print '' "Waiting for these jobs to finish..."
wait

countfiles -s $mydir
if eq REPLY num_files; then
	print "Succeeded: $REPLY files created. Cleaning up."
	rm -r $mydir
else
	print "Failed: $REPLY files created, should be $num_files." "Leaving directory '$mydir'."
fi
