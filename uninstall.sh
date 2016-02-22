#! /bin/sh

# Interactive uninstaller for modernish.
# https://github.com/modernish/modernish
#
# This uninstaller is itself an example of a modernish script (from '. modernish' on).
# For more conventional examples, see share/doc/modernish/examples
#
# --- begin license ---
# Copyright (c) 2016 Martijn Dekker <martijn@inlv.org>, Groningen, Netherlands
# 
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
# 
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# --- end license ---

# ensure sane default permissions
umask 022

# find directory uninstall.sh resides in; assume everything else is there too
case $0 in
( */* )	srcdir=${0%/*} ;;
( * )	srcdir=. ;;
esac
srcdir=$(cd "$srcdir" && pwd -P) || exit

# make bin/modernish findable in $PATH
PATH=$srcdir/bin:$PATH

# try to test-initialize modernish in a subshell to see if we can run it
if ! ( . modernish ); then
	echo
	echo "The shell executing this script can't run modernish. Try running uninstall.sh"
	echo "with a more fully POSIX-compliant shell, for instance: dash uninstall.sh"
	exit 3
fi 1>&2

# BUG_ALSUBSH workaround: on ksh93, aliases defined in subshells leak upwards into the main
# shell, so now we have aliases from the above test subshell interfering with initialising
# modernish for real below. Check for the test alias from the bug test.
alias BUG_ALSUBSH >/dev/null 2>&1 && unalias -a

# load modernish and some modules
. modernish
use safe -w BUG_APPENDC -w BUG_UPP	# IFS=''; set -f -u -C (declaring compat with bugs)
use sys/dirutils			# for 'traverse'
use var/string				# for 'prepend'

# abort program if any of these commands give an error
harden rm
harden rmdir

unset -v installroot
while not isset installroot; do
	print "* Enter the directory prefix from which to uninstall modernish."
	if eq UID 0; then
		print "  Just press 'return' to uninstall from /usr/local."
		echo -n "Directory prefix: "
		read -r installroot || exit 2 Aborting.
		empty $installroot && installroot=/usr/local
	else
		print "  Just press 'return' to uninstall from your home directory."
		echo -n "Directory prefix: "
		read -r installroot || exit 2 Aborting.
		empty $installroot && installroot=~
	fi
	if not exists $installroot; then
		echo "$installroot doesn't exist. Please try again."
		unset -v installroot
	elif not isdir -L $installroot; then
		print "$installroot is not a directory. Please try again."
		unset -v installroot
	fi
done

# Handler function for 'traverse': uninstall one file, remembering directories.
# Parameter: $1 = full source path for a file or directory.
# TODO: handle symlinks (if/when needed)
dirs_to_remove=''
uninstall_handler() {
	case ${1##*/} in
	( .* | _* | Makefile | *~ | *.bak )
		# ignore these (if directory, prune)
		return 1 ;;
	esac
	if isdir $1; then
		# remember for later: store shell-quoted and in reverse order
		prepend -Q dirs_to_remove $installroot${1#"$srcdir"}
	elif isreg $1; then
		relfilepath=${1#"$srcdir"/}
		if not contains $relfilepath /; then
			# ignore files at top level
			return 1
		fi
		destfile=$installroot/$relfilepath
		if exists $destfile; then
			echo "- Removing: $destfile "
			rm -f $destfile
		fi
	fi
}

# Traverse through the source directory, uninstalling corresponding destination files as we go.
traverse $srcdir uninstall_handler

# Remove collected directories.
eval set -- $dirs_to_remove	# set parameters from shell-quoted values
for dir do
	if isnonempty $dir; then
		echo "- Leaving non-empty directory $dir"
	elif exists $dir; then
		echo "- Removing empty directory $dir"
		rmdir $dir
	fi
done

print '' "Modernish $MSH_VERSION was uninstalled successfully from $installroot."
