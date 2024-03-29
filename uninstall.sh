#! /bin/sh

# Interactive uninstaller for modernish.
# https://github.com/modernish/modernish
#
# This uninstaller is itself an example of a modernish script (from '. modernish' on).
# For more conventional examples, see share/doc/modernish/examples
#
# --- begin license ---
# Copyright (c) 2019 Martijn Dekker <martijn@inlv.org>
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

min_posix='cd -P -- / && ! { ! case x in ( x ) : ${0##*/} || : $( : ) ;; esac; }'
if (eval "$min_posix") 2>/dev/null; then
	unset -v min_posix
else
	# this is an ancient Bourne shell (e.g. Solaris 10)
	sh -c "$min_posix" 2>/dev/null && exec sh -- "$0" ${1+"$@"}
	DEFPATH=`getconf PATH` 2>/dev/null || DEFPATH=/usr/xpg4/bin:/bin:/usr/bin:/sbin:/usr/sbin
	PATH=$DEFPATH:$PATH
	export PATH
	sh -c "$min_posix" 2>/dev/null && exec sh -- "$0" ${1+"$@"}
	echo "$0: Can't escape from obsolete shell. Run me with a POSIX shell." >&2
	exit 128
fi

case ${MSH_VERSION+s} in
( s )	echo "The modernish installer cannot be run by modernish itself." >&2
	exit 128 ;;
esac

# semi-safe mode (compatible with broken shells)
set -o noglob +o noclobber +o nounset +o errexit +o allexport
IFS='
'

# find my own absolute directory path
unset -v CDPATH
case $0 in
( */* )	MSH_PREFIX=${0%/*} ;;
( * )	MSH_PREFIX=. ;;
esac
case $MSH_PREFIX in
( */* | [!+-]* | [+-]*[!0123456789]* )
	MSH_PREFIX=$(cd -P -- "$PWD" && cd -- "$MSH_PREFIX" && pwd -P && echo X) ;;
( * )	MSH_PREFIX=$(cd -P -- "$PWD" && cd "./$MSH_PREFIX" && pwd -P && echo X) ;;
esac || exit
MSH_PREFIX=${MSH_PREFIX%?X}
cd "$MSH_PREFIX" || exit

# put the shell in standards mode
. lib/modernish/adj/std.sh

# ensure sane default permissions
umask 022

usage() {
	echo "usage: $0 [ -n ] [ -f ] [ -d INSTALLROOT ]"
	echo "	-n: non-interactive operation"
	echo "	-f: delete */modernish directories even if files left"
	echo "	-d: specify root directory of modernish installation to uninstall"
	exit 1
} 1>&2

# parse options
unset -v opt_n opt_f installroot DEFPATH
case ${1-} in
( --relaunch )
	shift ;;
( * )	unset -v MSH_SHELL ;;
esac
while getopts 'nfd:' opt; do
	case $opt in
	( \? )	usage ;;
	( n )	opt_n='' ;;		# non-interactive operation
	( f )	opt_f='' ;;		# force: delete */modernish/* directories if content left
	( d )	installroot=$OPTARG ;;	# directory: specify install root directory
	esac
done
case $((OPTIND - 1)) in
( $# )	;;
( * )	usage ;;
esac

# determine and/or validate DEFPATH
. lib/modernish/adj/defpath.sh || exit
export DEFPATH

# find a compliant POSIX shell
case ${MSH_SHELL-} in
( '' )	if command -v modernish >/dev/null; then
		read -r MSH_SHELL <"$(command -v modernish)" 2>/dev/null && MSH_SHELL=/${MSH_SHELL#*/}
	fi
	. lib/modernish/adj/goodsh.sh || exit
	case $(command . lib/modernish/adj/fatal.sh || echo BUG) in
	( "${PPID:-no_match_on_no_PPID}" ) ;;
	( * )	echo "Bug attack! Abandon shell!" >&2
		echo "Relaunching ${0##*/} with $MSH_SHELL..." >&2
		exec "$MSH_SHELL" "$MSH_PREFIX/${0##*/}" --relaunch "$@" ;;
	esac ;;
esac

# load modernish and some modules
. bin/modernish
use safe				# IFS=''; set -f -u -C
use sys/cmd/harden
use var/arith/cmp			# arithmetic comparison shortcuts: eq, gt, etc.
use var/loop/find -b			# '-b' allows compatibility mode for obsolete/broken 'find' util
use sys/base/readlink
use sys/base/which			# for modernish version of 'which'
use sys/dir/countfiles

# ********** from here on, this is a modernish script *************

# abort program if any of these commands give an error; trace 'rm' and 'rmdir'
harden -p -t rm
harden -p -t rmdir
harden -p ls

# validate options
if isset installroot; then
	is -L dir $installroot || exit 1 "not a directory: $installroot"
	# If uninstalling from root dir, avoid concatenation creating initial double slash (UNC/Cygwin compat).
	if str eq $installroot /; then
		installroot=/.
	fi
fi

# Define a function to check if a file is to be ignored/skipped.
if command -v git >/dev/null && command git check-ignore --quiet foo~ 2>/dev/null; then
	# If we're installing from git repo, make is_ignored() ask git to check against .gitignore.
	harden -f is_ignored -e '>1' git check-ignore --quiet --
else
	is_ignored() {
		case $1 in
		( "$MSH_PREFIX"/_* | */.* | *~ | *.bak | *.orig | *.rej ) ;;
		( * )	return 1 ;;
		esac
	}
fi


# --- Main ---

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
			putln	'* Choose the directory prefix from which to uninstall modernish,' \
				"  or enter another prefix (starting with '/')."
			LOOP select installroot in "$@"; DO
				if str empty $installroot && str begin $REPLY /; then
					installroot=$REPLY
				fi
				if not str empty $installroot; then
					break
				fi
			DONE
			str empty $REPLY && exit 2 Aborting.	# user pressed ^D
		fi
	else
		# we did not detect existing installations
		if isset opt_n; then
			exit 1 "No existing modernish installation was found in your PATH."
		fi
		putln "* No existing modernish installation was found in your PATH." \
		      "  Enter the directory prefix from which to uninstall modernish."
		if is -L dir /usr/local && can write /usr/local; then
			putln "  Just press 'return' to uninstall from /usr/local."
			put "Directory prefix: "
			read -r installroot || exit 2 Aborting.
			str empty $installroot && installroot=/usr/local
		else
			putln "  Just press 'return' to uninstall from your home directory."
			put "Directory prefix: "
			read -r installroot || exit 2 Aborting.
			str empty $installroot && installroot=~
		fi
	fi
	if not is present $installroot; then
		putln "$installroot doesn't exist. Please try again."
	elif not is -L dir $installroot; then
		putln "$installroot is not a directory. Please try again."
	fi
done

# Remove sh compatibility symlink, if present.
compatdir=lib/modernish/bin
if is sym $installroot/$compatdir/sh; then
	# 'LOOP find' below will need a working $MSH_SHELL
	readlink -ms $installroot/$compatdir/sh
	MSH_SHELL=$REPLY
	. lib/modernish/adj/goodsh.sh || exit
	not isset opt_f && rm $installroot/$compatdir/sh <&-
fi

# Remove '[' symlink (Solaris), if present.
is sym $installroot/$compatdir/[ && rm $installroot/$compatdir/[ <&-

# Handle top-level documentation files specially.
if not isset opt_f; then
	LOOP for --glob docfile in *.md [$ASCIIUPPER][$ASCIIUPPER]*; DO
		destfile=$installroot/share/doc/modernish/$docfile
		if is reg $destfile; then
			rm $destfile <&-
		fi
	DONE
fi

# Flag to remember whether we've actually done anything. This is so we
# don't give an "uninstalled successfully" message if nothing happened.
unset -v flag

# Traverse through the source directory, uninstalling corresponding destination files
# and directories as we go. This strategy ensures we don't delete anything we shouldn't.
# If option -f was given, remove */modernish/* and */modernish directories even if files are left.
# Directories must be emptied first, so use depth-first traversal.
# Parameter: $1 = full source path for a file or directory.
# NOTE: no 'rm -f', please; we need to die() on error such as 'file not found'.
# Any interactivity is suppressed by closing standard input instead ('<&-').
set -- -path ./_* -or -path */.* -or -path ./lib/_install -or -path ./lib/_install/*
if isset opt_f; then
	# On -f, skip files in */modernish dirs, as those dirs are deleted recursively.
	set -- "$@" -or -path */modernish/*
fi
LOOP find F in . -depth -not '(' "$@" ')' -iterate; DO
	if is_ignored $F; then
		continue
	fi
	if is reg $F; then
		relfilepath=${F#./}
		if not str in $relfilepath /; then
			# ignore files at top level
			continue
		fi
		case $relfilepath in
		( "$compatdir"/*.inactive)
			destfile=$installroot/${relfilepath%.inactive} ;;
		( * )	destfile=$installroot/$relfilepath ;;
		esac
		if is reg $destfile; then
			flag=
			rm $destfile <&-
		fi
	elif is dir $F && not str eq $F .; then
		absdir=${F#.}
		destdir=$installroot$absdir
		if isset opt_f && is dir $destdir && str end $destdir '/modernish'; then
			flag=
			rm -r $destdir <&-
		elif is nonempty $destdir; then
			countfiles -s $destdir
			if str in $destdir '/modernish/' || str end $destdir '/modernish'; then
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
DONE

if isset flag; then
	putln '' "Modernish $MSH_VERSION was uninstalled successfully from $installroot."
else
	exit 1 "No modernish installation found at $installroot."
fi
