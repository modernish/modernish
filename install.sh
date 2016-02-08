#! /bin/sh

# Interactive installer for modernish.
# https://github.com/modernish/modernish
#
# This installer is itself an example of a modernish script (from '. modernish' on).
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

# find directory install.sh resides in; assume everything else is there too
case $0 in
( */* )	srcdir=${0%/*} ;;
( * )	srcdir=. ;;
esac
srcdir=$(cd "$srcdir" && pwd -P) || exit

# make bin/modernish findable in $PATH
oldPATH=$PATH
PATH=$srcdir/bin:$PATH

# try to test-initialize modernish in a subshell to see if we can run it
if ! ( . modernish ) 2>/dev/null; then
	echo "The shell executing this script can't run modernish. Try running"
	echo "install.sh with another POSIX shell, for instance: dash install.sh"
	exit 3
fi 1>&2

# load modernish and some modules
. modernish
use safe -w BUG_APPENDC -w BUG_UPP
use var/setlocal -w BUG_FNSUBSH
use loop/select
use sys/dirutils			# for 'traverse'
use var/string				# for 'trim'

# abort program if any of these commands give an error
harden cd
harden grep 'gt 1'
harden mkdir
harden cp
harden sed
harden fold

# (style note: modernish library functions never have underscores or capital
# letters in them, so using underscores or capital letters is a good way to
# avoid potential conflicts with future library functions, as well as an
# easy way for readers of your code to tell them apart.)

# function that lets the user choose a shell from /etc/shells or provide their own path,
# verifies that the shell can run modernish, then relaunches the script with that shell
pick_shell_and_relaunch() {
	print '' "Please choose a default shell for executing modernish scripts." \
		"Either pick a shell from the menu (gleaned from your local /etc/shells)," \
		"or enter the full path of another POSIX-compliant shell at the prompt."
	all_shells=$(LC_ALL=C; grep -E '^/[a-z/]+/[a-z]*sh[0-9]*$' /etc/shells \
		| grep -vE '(csh$|/fish$|/r[a-z]+)$')
	empty $all_shells && all_shells='(none found; enter path)'
	setlocal --split=$CCn PS3='Shell number or path: '
		# field splitting: split grep output ($all_shells) by newline ($CCn)
		select msh_shell in $all_shells; do
			if empty $msh_shell && not empty $REPLY; then
				# a path instead of a number was given
				msh_shell=$REPLY
			fi
			if not canexec $msh_shell; then
				echo "$msh_shell does not seem to be executable. Try another."
			elif not $msh_shell -c '. modernish' 2>/dev/null; then
				echo "$msh_shell was found unable to run modernish. Try another."
			else
				break
			fi
		done
	endlocal
	empty $REPLY && exit 2 Aborting.	# user pressed ^D
	print "* Relaunching installer with $msh_shell" ''
	exec $msh_shell $0 _Msh_shell=$msh_shell
}

# Simple function to ask a question of a user.
yesexpr=$(locale yesexpr 2>/dev/null) || yesexpr=^[yY].*
ask_q() {
	REPLY=''
	while empty $REPLY; do
		echo -n "$1 "
		read -r REPLY || exit 2 Aborting.
	done
	ematch $REPLY $yesexpr
}

case ${1-} in
( _Msh_shell=* )
	msh_shell=${1#_Msh_shell=}
	print "* Modernish version $MSH_VERSION, running on $msh_shell".
	print "This shell has: $MSH_CAP" | fold -s | sed 's/^/  /' ;;
( * )
	print "* Modernish version $MSH_VERSION."
	print "Current shell has: $MSH_CAP" | fold -s | sed 's/^/  /'
	pick_shell_and_relaunch ;;
esac

if ( eval '[ -n "${.sh.version+s}" ]' ) 2>/dev/null; then
	print "* Error: $msh_shell is ksh93, for which the '#!/usr/bin/env modernish'" \
		"  hashbang path doesn't work (alias-based commands are not found)." \
		"  Unfortunately, it is not possible to use ksh93 as the default shell." \
		"  You can still use '#!$msh_shell' followed by '. modernish'."
	pick_shell_and_relaunch
fi

unset -v shellwarning
if thisshellhas BUG_UPP; then
	print "* Warning: this shell has BUG_UPP, complicating 'use safe' (set -u)."
	shellwarning=y
fi
if thisshellhas BUG_APPENDC; then
	print "* Warning: this shell has BUG_APPENDC, complicating 'use safe' (set -C)."
	shellwarning=y
fi
if thisshellhas BUG_FNSUBSH; then
	# this is only ksh93, so this should never happen, but just in case...
	print "* Warning: this shell has BUG_FNSUBSH, complicating 'use var/setlocal'."
	shellwarning=y
fi
if isset shellwarning; then
	print "  Using this shell as the default shell is possible, but not recommended." \
		"  Modernish itself works around these bug(s), but some modernish scripts" \
		"  that have not implemented relevant workarounds may refuse to run."
fi

ask_q "Are you happy with $msh_shell as the default shell? (y/n)" || pick_shell_and_relaunch

unset -v installroot
while not isset installroot; do
	print "* Enter the directory prefix for installing modernish."
	if eq UID 0; then
		print "  Just press 'return' to install in /usr/local."
		echo -n "Directory prefix: "
		read -r installroot || exit 2 Aborting.
		empty $installroot && installroot=/usr/local
	else
		print "  Just press 'return' to install in your home directory."
		echo -n "Directory prefix: "
		read -r installroot || exit 2 Aborting.
		empty $installroot && installroot=~
	fi
	if not exists $installroot; then
		ask_q "$installroot doesn't exist yet. Create it? (y/n)" || unset -v installroot
	elif not isdir -L $installroot; then
		print "$installroot is not a directory. Please try again."
		unset -v installroot
	fi
done

umask 022

# Handler function for 'traverse': install one file or directory.
# Parameter: $1 = full source path for a file or directory.
# TODO: handle symlinks (if/when needed)
install_handler() {
	case ${1##*/} in
	( .* | _* | Makefile | *~ | *.bak )
		# ignore these (if directory, prune)
		return 1 ;;
	esac
	if isdir $1; then
		absdir=${1#"$srcdir"}
		destdir=$installroot$absdir
		if not exists $destdir; then
			echo "- Creating directory: $destdir"
			mkdir -p $destdir
		fi
	elif isreg $1; then
		relfilepath=${1#"$srcdir"/}
		if not contains $relfilepath /; then
			# ignore files at top level
			return 1
		fi
		destfile=$installroot/$relfilepath
		if exists $destfile; then
			exit 3 "Fatal error: '$destfile' already exists, refusing to overwrite"
		fi
		echo -n "- Installing: $destfile "
		if identic $relfilepath bin/modernish; then
			echo -n "(hashbang path: #! $msh_shell) "
			sed "1 s|.*|#! $msh_shell|" < $1 > $destfile
		else
			cp -p $1 $destfile
		fi
		read -r firstline < $1
		if startswith $firstline '#!'; then
			# make scripts executable
			chmod 755 $destfile
			echo "(executable)"
		else
			chmod 644 $destfile
			echo "(not executable)"
		fi
	fi
}

# Traverse through the source directory, installing files as we go.
traverse $srcdir install_handler

print '' "Modernish $MSH_VERSION installed successfully with default shell $msh_shell." \
	"Be sure $installroot/bin is in your \$PATH before starting." \
