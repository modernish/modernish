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
cd "$srcdir" || exit

usage() {
	echo "usage: $0 [ -n ] [ -f ] [ -d INSTALLROOT ]"
	echo "	-n: non-interactive operation"
	echo "	-f: delete */modernish directories even if files left"
	echo "	-d: specify root directory of modernish installation to uninstall"
	exit 1
} 1>&2

# parse options
unset -v opt_n opt_f installroot
while getopts 'nfd:' opt; do
	case $opt in
	( \? )	usage ;;
	( n )	opt_n='' ;;		# non-interactive operation
	( f )	opt_f='' ;;		# force: delete */modernish/* directories if content left
	( d )	installroot=$OPTARG ;;	# directory: specify install root directory
	esac
done
shift $(($OPTIND - 1))
case $# in
( [!0]* ) usage ;;
esac

# Since we're running the source-tree copy of modernish and not the installed copy,
# manually make sure that $MSH_SHELL is a shell with $PPID; this is essential for
# insubshell() and things that depend on it, such as die().
# At least as of Jan 19 2014, NetBSD /bin/sh is a shell without $PPID (and
# lots of other missing features mandated by POSIX).
MSH_SHELL=''
if command -v modernish >/dev/null 2>&1; then
	# the below does not work on older 'dash' because of an IFS bug with 'read'
	IFS="#!$IFS" read junk junk MSH_SHELL junk <"$(command -v modernish)"
fi
for MSH_SHELL in "$MSH_SHELL" /bin/sh dash yash bash ksh ksh93 mksh oksh pdksh zsh zsh4 zsh5 ash; do
	command -v "$MSH_SHELL" >/dev/null 2>&1 || continue
	case $("$MSH_SHELL" -c 'echo "$PPID"') in
	( '' | *[!0123456789]* )
		MSH_SHELL=''
		continue ;;
	( * )	MSH_SHELL=$(command -v "$MSH_SHELL")
		break ;;
	esac
done
case $MSH_SHELL in
( '' )	echo "Fatal: can't find any shell with \$PPID!" 1>&2
	exit 125 ;;
esac

# try to test-initialize modernish in a subshell to see if we can run it
#
# On ksh93, subshells are normally handled specially without forking. Depending
# on the version of ksh93, bugs cause various things to leak out of the
# subshell into the main shell (e.g. aliases, see BUG_ALSUBSH). This may
# prevent the proper init of modernish later. To circumvent this problem, force
# the forking of a real subshell by making it a background job.
if ! { (eval ". bin/modernish") & wait "$!"; }; then
	echo
	echo "The shell executing this script can't run modernish. Try running uninstall.sh"
	echo "with a more fully POSIX-compliant shell, for instance: dash uninstall.sh"
	exit 3
fi 1>&2

# load modernish and some modules
. bin/modernish
use safe -w BUG_APPENDC -w BUG_UPP	# IFS=''; set -f -u -C (declaring compat with bugs)
use var/arith/cmp			# arithmetic comparison shortcuts: eq, gt, etc.
use loop/select -w BUG_SELECTEOF \
		-w BUG_SELECTRPL	# ksh/zsh/bash 'select' now on all POSIX shells
use sys/base/which			# for modernish version of 'which'
use sys/dir				# for 'traverse' and 'countfiles'
use var/string				# for 'replacein'
use sys/user/id -f			# for $UID (and $USER)

# ********** from here on, this is a modernish script *************

# abort program if any of these commands give an error; trace 'rm' and 'rmdir'
harden -p -t rm
harden -p -t rmdir
harden -p ls

# validate options
if isset installroot; then
	is -L dir $installroot || exit 1 "not a directory: $installroot"
fi

# detect existing modernish installations from $PATH, storing their install
# prefixes in the positional parameters (strip 2 path elements: /bin/modernish)
which -aQsP2 modernish
eval "set -- $REPLY"	# which -Q gives shellquoted output for safe 'eval'

while not isset installroot || not is -L dir $installroot; do
	if gt $# 0; then
		if isset opt_n; then
			# non-interactive mode: uninstall the first one found
			installroot=$1
		else
			# we detected existing installations: present a menu
			put '* Choose the directory prefix from which to uninstall modernish'
			if thisshellhas BUG_SELECTRPL; then
				putln '.'
			else
				putln ',' "  or enter another prefix (starting with '/')."
			fi
			REPLY=''  # BUG_SELECTEOF workaround
			select installroot; do
				if empty $installroot && startswith $REPLY /; then
					installroot=$REPLY
				fi
				if not empty $installroot; then
					break
				fi
			done
			empty $REPLY && exit 2 Aborting.	# user pressed ^D
		fi
	else
		# we did not detect existing installations
		if isset opt_n; then
			exit 1 "No existing modernish installation was found in your PATH."
		fi
		putln "* No existing modernish installation was found in your PATH." \
		      "  Enter the directory prefix from which to uninstall modernish."
		if eq UID 0; then
			putln "  Just press 'return' to uninstall from /usr/local."
			put "Directory prefix: "
			read -r installroot || exit 2 Aborting.
			empty $installroot && installroot=/usr/local
		else
			putln "  Just press 'return' to uninstall from your home directory."
			put "Directory prefix: "
			read -r installroot || exit 2 Aborting.
			empty $installroot && installroot=~
		fi
	fi
	if not is present $installroot; then
		putln "$installroot doesn't exist. Please try again."
	elif not is -L dir $installroot; then
		putln "$installroot is not a directory. Please try again."
	fi
done

# Remove zsh compatibility symlink, if present.
zcsd=$installroot/libexec/modernish/zsh-compat
is sym $zcsd/sh && rm $zcsd/sh
is dir $zcsd && not is nonempty $zcsd && rmdir $zcsd

# Handle README.md specially.
if is reg $installroot/share/doc/modernish/README.md; then
	rm $installroot/share/doc/modernish/README.md
fi

# Flag to remember whether we've actually done anything. This is so we
# don't give an "uninstalled successfully" message if nothing happened.
unset -v flag

# Handler function for 'traverse': uninstall one file or directory.
# If option -f was given, remove */modernish/* and */modernish directories even if files are left.
# Directories must be emptied first, so use depth-first traversal.
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
			flag=
			rm $destfile </dev/null		# no 'rm -f', please; we want to stop on error.
		fi
	elif is dir $1 && not identic $1 $srcdir; then
		absdir=${1#"$srcdir"}
		destdir=$installroot$absdir
		if isset opt_f && is dir $destdir && { contains $destdir '/modernish/' || endswith $destdir '/modernish'; }
		then	# option -f: delete directories ending with */modernish regardless of their contents
			if is nonempty $destdir; then
				countfiles -s $destdir
				putln "- WARNING: $REPLY stray item(s) left in $destdir, '-f' given, deleting anyway:"
				ls -lA $destdir
			fi
			flag=
			rm -r $destdir </dev/null	# no 'rm -rf', please; we want to stop on error.
		elif is nonempty $destdir; then
			countfiles -s $destdir
			if contains $destdir '/modernish/' || endswith $destdir '/modernish'; then
				putln "- Warning: keeping $REPLY stray item(s) in $destdir:"
				ls -lA $destdir
			else
				putln "- Keeping non-empty directory $destdir ($REPLY item(s) left)"
			fi
		elif is dir $destdir; then
			flag=
			rmdir $destdir
		fi
	fi
}

# Traverse depth-first through the source directory, uninstalling
# corresponding destination files and directories as we go.
# This strategy ensures we don't delete anything we shouldn't.
traverse -d $srcdir uninstall_handler

if isset flag; then
	putln '' "Modernish $MSH_VERSION was uninstalled successfully from $installroot."
else
	exit 1 "No modernish installation found at $installroot."
fi
