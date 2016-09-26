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
use var/arith/cmp			# arithmetic comparison shortcuts: eq, gt, etc.
use loop/select				# ksh/zsh/bash 'select' now on all POSIX shells
use sys/base/which			# for modernish version of 'which'
use sys/dir/traverse			# for 'traverse'
use var/string				# for 'replacein'
use sys/user/id -f			# for $UID (and $USER)

# abort program if any of these commands give an error
harden rm
harden rmdir

# detect existing modernish installations from $PATH, storing their install
# prefixes in the positional parameters (strip 2 path elements: /bin/modernish)
which -aQsP2 modernish || exit 1 "Internal error: Cannot find modernish!"
eval "set -- $REPLY"	# which -Q gives shellquoted output for safe 'eval'
shift			# skip the first one: it's our source directory

unset -v installroot
while not isset installroot; do
	if gt $# 0; then
		# we detected existing installations: present a menu
		print "* Choose the directory prefix from which to uninstall modernish,"
		print "  or enter another prefix (starting with '/')."
		REPLY=''
		select installroot; do
			if empty $installroot && startswith $REPLY /; then
				installroot=$REPLY
			fi
			if not empty $installroot; then
				break
			fi
		done
		empty $REPLY && exit 2 Aborting.	# user pressed ^D
	else
		# we did not detect existing installations
		print "* No existing modernish installation was found in your PATH." \
		      "  Enter the directory prefix from which to uninstall modernish."
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
	fi
	if not is present $installroot; then
		echo "$installroot doesn't exist. Please try again."
		unset -v installroot
	elif not is -L dir $installroot; then
		print "$installroot is not a directory. Please try again."
		unset -v installroot
	fi
done

# Remove zsh compatibility symlink, if present.
zcsd=$installroot/libexec/modernish/zsh-compat
is sym $zcsd/sh && rm -f $zcsd/sh
is dir $zcsd && not is nonempty $zcsd && rmdir $zcsd

# Handler function for 'traverse': uninstall one file, remembering directories.
# Parameter: $1 = full source path for a file or directory.
uninstall_handler() {
	case ${1#"$srcdir"} in
	( */.* | */_* | */Makefile | *~ | *.bak )
		# ignore these
		return 1 ;;
	esac

	if is reg $1; then
		relfilepath=${1#"$srcdir"/}
		if not contains $relfilepath /; then
			# ignore files at top level
			return 1
		fi
		destfile=$installroot/$relfilepath
		if is reg $destfile; then
			echo "- Removing: $destfile "
			rm -f $destfile
		fi
	elif is dir $1 && not identic $1 $srcdir; then
		absdir=${1#"$srcdir"}
		destdir=$installroot$absdir
		if is nonempty $destdir; then
			echo "- Leaving non-empty directory $destdir"
		elif is dir $destdir; then
			echo "- Removing empty directory $destdir"
			rmdir $destdir
		fi
	fi
}

# Traverse depth-first through the source directory, uninstalling
# corresponding destination files and directories as we go.
traverse -d $srcdir uninstall_handler

print '' "Modernish $MSH_VERSION was uninstalled successfully from $installroot."
