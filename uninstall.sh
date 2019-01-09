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

# Since we're running the source-tree copy of modernish and not the
# installed copy, manually make sure that $MSH_SHELL is a shell with POSIX
# 'kill -s SIGNAL' syntax and without the cmd subst unbalanced quote bug,
# FTL_DEVCLOBBR, FTL_ARITHPREC, FTL_PARONEARG, FTL_NOPPID, FTL_FNREDIR,
# FTL_PSUB, FTL_BRACSQBR, FTL_DEVCLOBBR, FTL_NOARITH, FTL_UPP or FTL_UNSETFAIL.
# These selected fatal bug tests should lock out most release versions that
# cannot run modernish. Search these IDs in bin/modernish for documentation.
test_cmds='test -c /dev/tty >/dev/tty && dev=tty || dev=null
set -C && : $( : # buggy shells don'\'' tolerate an apostrophe here
) >"/dev/$dev" && case $((37-16%7+9)) in ( 44 )
IFS= && set -fCu && set 1 2 3 && set "$@" && [ "$#" -eq 3 ] &&
f() { echo x; } >&2 && case $(f 2>/dev/null) in ("")
t=barbarfoo; case ${t##bar*}/${t%%*} in (/)
t=]abcd; case c in (*["$t"]*) case e in (*[!"$t"]*)
set -fuC && set -- >/dev/null && kill -s 0 "$$" "$@" && j=0 &&
unset -v _Msh_foo$((((j+=6*7)==0x2A)>0?014:015)) && echo "$PPID"
;; esac;; esac;; esac;; esac;; esac'
case ${MSH_SHELL-} in
( '' )	if command -v modernish >/dev/null; then
		IFS="#!$IFS" read junk junk MSH_SHELL junk <"$(command -v modernish)"
	fi
	for MSH_SHELL in "$MSH_SHELL" sh /bin/sh ash dash zsh5 zsh ksh ksh93 lksh mksh yash bash; do
		if ! command -v "$MSH_SHELL" >/dev/null; then
			MSH_SHELL=''
			continue
		fi
		case $(exec "$MSH_SHELL" -c "$test_cmds" 2>/dev/null) in
		( $$ )	MSH_SHELL=$(command -v "$MSH_SHELL")
			export MSH_SHELL
			break ;;
		( * )	MSH_SHELL=''
			continue ;;
		esac
	done
	case $MSH_SHELL in
	( '' )	echo "Fatal: can't find any suitable POSIX compliant shell!" 1>&2
		exit 128 ;;
	esac
	case $(eval "$test_cmds" 2>/dev/null) in
	( '' | *[!0123456789]* )
		echo "Bug attack! Abandon shell!" >&2
		echo "Relaunching ${0##*/} with $MSH_SHELL..." >&2
		exec "$MSH_SHELL" "$0" "$@" ;;
	esac ;;
( * )	case $(exec "$MSH_SHELL" -c "$test_cmds" 2>/dev/null) in
	( $$ )	;;
	( * )	echo "Shell $MSH_SHELL is not a suitable POSIX compliant shell." >&2
		exit 1 ;;
	esac ;;
esac

# find directory uninstall.sh resides in; assume everything else is there too
case $0 in
( */* )	srcdir=${0%/*} ;;
( * )	srcdir=. ;;
esac
srcdir=$(cd "$srcdir" && pwd -P && echo X) || exit
srcdir=${srcdir%?X}
cd "$srcdir" || exit

# try to test-initialize modernish in a subshell to see if we can run it
if ! (eval ". bin/modernish"); then
	echo
	echo "The shell executing this script can't run modernish. Try running uninstall.sh"
	echo "with a more fully POSIX-compliant shell, for instance: dash uninstall.sh"
	exit 3
fi 1>&2

# load modernish and some modules
. bin/modernish
use safe				# IFS=''; set -f -u -C
use sys/cmd/harden
use var/arith/cmp			# arithmetic comparison shortcuts: eq, gt, etc.
use var/loop/find
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
			putln	'* Choose the directory prefix from which to uninstall modernish,' \
				"  or enter another prefix (starting with '/')."
			LOOP select installroot in "$@"; DO
				if str empty $installroot && str left $REPLY /; then
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

# Remove zsh compatibility symlink, if present.
zcsd=$installroot/libexec/modernish/zsh-compat
if is sym $zcsd/sh; then
	# 'LOOP find' below will need a working $MSH_SHELL
	MSH_SHELL=$(use sys/base/readlink; readlink -f $zcsd/sh)
	rm $zcsd/sh <&-
fi
is dir $zcsd && not is nonempty $zcsd && rmdir $zcsd

# Handle README.md specially.
if is reg $installroot/share/doc/modernish/README.md; then
	rm $installroot/share/doc/modernish/README.md <&-
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
LOOP find F in . -depth ! '(' -path */[._]* -o -name *~ -o -name *.bak ')'; DO
	if is reg $F; then
		relfilepath=${F#./}
		if not str in $relfilepath /; then
			# ignore files at top level
			continue
		fi
		destfile=$installroot/$relfilepath
		if is reg $destfile; then
			flag=
			is reg $destfile.zwc && zwcfile=$destfile.zwc || zwcfile=   # zsh word code
			rm $destfile $zwcfile <&-
		fi
	elif is dir $F && not str id $F .; then
		absdir=${F#.}
		destdir=$installroot$absdir
		if isset opt_f && is dir $destdir && { str in $destdir '/modernish/' || str right $destdir '/modernish'; }
		then	# option -f: delete directories ending with */modernish regardless of their contents
			if is nonempty $destdir; then
				countfiles -s $destdir
				putln "- WARNING: $REPLY stray item(s) left in $destdir, '-f' given, deleting anyway:"
				ls -lA $destdir
			fi
			flag=
			rm -r $destdir <&-
		elif is nonempty $destdir; then
			countfiles -s $destdir
			if str in $destdir '/modernish/' || str right $destdir '/modernish'; then
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
