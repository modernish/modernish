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

# ensure sane default permissions
umask 022

# find directory install.sh resides in; assume everything else is there too
case $0 in
( */* )	srcdir=${0%/*} ;;
( * )	srcdir=. ;;
esac
srcdir=$(cd "$srcdir" && pwd -P) || exit
cd "$srcdir" || exit

# commands for test-initialising modernish
# test thisshellhas(): a POSIX reserved word, POSIX special builtin, and POSIX regular builtin
test_modernish='. bin/modernish || exit
thisshellhas --rw=if --bi=set --bi=wait || exit 1 "Failed to determine a working thisshellhas() function."'

# Since we're running the source-tree copy of modernish and not the
# installed copy, manually make sure that $MSH_SHELL is a shell with both
# POSIX 'kill -s SIGNAL' syntax and $PPID; these are essential for correct
# initialisation of modernish.
# At least as of Jan 19 2014, NetBSD /bin/sh is a shell without $PPID (and
# lots of other missing features mandated by POSIX). Solaris /bin/sh
# is an original Bourne shell with the ancient 'kill -SIGNAL' syntax,
# which was marked as an optional extension in POSIX.
case ${MSH_SHELL-} in
( '' )	for MSH_SHELL in sh dash yash bash ksh ksh93 mksh oksh pdksh zsh zsh4 zsh5 ash; do
		command -v "$MSH_SHELL" >/dev/null 2>&1 || continue
		case $("$MSH_SHELL" -c 'kill -s 0 "$$" && echo "$PPID"' 2>/dev/null) in
		( '' | *[!0123456789]* )
			MSH_SHELL=''
			continue ;;
		( * )	MSH_SHELL=$(command -v "$MSH_SHELL")
			break ;;
		esac
	done
	case $MSH_SHELL in
	( '' )	echo "Fatal: can't find any shell with 'kill -s' and \$PPID!" 1>&2
		exit 125 ;;
	esac ;;
esac

# Let test initialisations of modernish in other shells use this result.
export MSH_SHELL

# try to test-initialize modernish in a subshell to see if we can run it
#
# On ksh93, subshells are normally handled specially without forking. Depending
# on the version of ksh93, bugs cause various things to leak out of the
# subshell into the main shell (e.g. aliases, see BUG_ALSUBSH). This may
# prevent the proper init of modernish later. To circumvent this problem, force
# the forking of a real subshell by making it a background job.
if ! { (eval "$test_modernish") & wait "$!"; }; then
	echo
	echo "install.sh: The shell executing this script can't run modernish. Try running"
	echo "            it with another POSIX shell, for instance: dash install.sh"
	exit 3
fi 1>&2

# load modernish and some modules
. bin/modernish
use safe -w BUG_APPENDC -w BUG_UPP	# IFS=''; set -f -u -C (declaring compat with bugs)
use var/setlocal -w BUG_FNSUBSH		# setlocal is like zsh anonymous functions
use var/arith/cmp			# arithmetic comparison shortcuts: eq, gt, etc.
use loop/select -w BUG_SELECTRPL \
	-w BUG_SELECTEOF		# ksh/zsh/bash 'select' now on all POSIX shells (declare mksh & zsh bug workarounds)
use sys/base				# for 'mktemp', 'which' and 'readlink'
use sys/dir/traverse			# for 'traverse'
use var/string				# for 'trim' and 'append'
use sys/user/id -f			# for $UID (and $USER)

# abort program if any of these commands give an error
# (the default error condition is '> 0', exit status > 0;
# for some commands, such as grep, this is different)
# also make sure the system default path is used to find them (-p)
harden -p cd
harden -p -t mkdir
harden -p cp
harden -p chmod
harden -p ln
harden -p -e '> 1' LC_ALL=C grep
harden -p sed
harden -p sort
harden -p paste
harden -p fold

# (Does the script below seem like it makes lots of newbie mistakes with not
# quoting variables and glob patterns? Think again! Using the 'safe' module
# disables field splitting and globbing, along with all their hazards: most
# variable quoting is unnecessary and glob patterns can be passed on to
# commands such as 'match' without quoting. In the one instance where this
# script needs field splitting, it is enabled locally using 'setlocal', and
# splits only on the one needed separator character. Globbing is not needed
# or enabled at all.)

# (style note: modernish library functions never have underscores or capital
# letters in them, so using underscores or capital letters is a good way to
# avoid potential conflicts with future library functions, as well as an
# easy way for readers of your code to tell them apart.)

# function that lets the user choose a shell from /etc/shells or provide their own path,
# verifies that the shell can run modernish, then relaunches the script with that shell
pick_shell_and_relaunch() {
	clear_eol=$(tput el)	# clear to end of line

	# find shells, eliminating duplicates (symlinks, hard links) and non-compatible shells
	which -as sh ash bash dash yash zsh zsh4 zsh5 ksh ksh93 pdksh mksh lksh oksh
	shells_to_test=$REPLY	# newline-separated list of shells to test
	# supplement 'which' results with any additional shells from /etc/shells
	if can read /etc/shells; then
		shells_to_test=${shells_to_test}${CCn}$(grep -E '^/[a-z/][a-z0-9/]+/[a-z]*sh[0-9]*$' /etc/shells |
			grep -vE '(csh|/esh|/psh|/posh|/fish|/r[a-z])')
	fi

	setlocal REPLY PS3 valid_shells='' --split=$CCn
		# Within this 'setlocal' block: local positional parameters; local variables REPLY, PS3 and
		# valid_shells; field splitting on newline (i.e. another way of declaring the local variable IFS=$CCn).
		# Field splitting on newline means that any expansions that may contain a newline must be quoted
		# (unless they are to be split, of course -- like in the 'for' and 'select' statements).

		for shell in $shells_to_test; do
			for alreadyfound in $valid_shells; do
				if is samefile $shell $alreadyfound; then
					continue 2
				fi
			done
			readlink -fs $shell && not endswith $REPLY /busybox && shell=$REPLY
			echo -n "${CCr}Testing shell $shell...$clear_eol"
			if can exec $shell && $shell -c $test_modernish 2>/dev/null; then
				append "--sep=$CCn" valid_shells $shell
			fi
		done

		print "${CCr}Please choose a default shell for executing modernish scripts.$clear_eol"

		if thisshellhas BUG_SELECTRPL; then
			# On mksh with this bug, "select" doesn't store non-menu input in $REPLY,
			# so install.sh can't offer this feature.
			PS3='Shell number: '
		else
			print	"Either pick a shell from the menu, or enter the command name or path" \
				"of another POSIX-compliant shell at the prompt."
			PS3='Shell number, command name or path: '
		fi

		if empty "$valid_shells"; then
			valid_shells='(no POSIX-compliant shell found; enter path)'
		else
			valid_shells=$(print "$valid_shells" | sort)
		fi
		REPLY='' # BUG_SELECTEOF workaround (zsh)
		select msh_shell in $valid_shells; do
			if empty $msh_shell && not empty $REPLY; then
				# a path or command instead of a number was given
				msh_shell=$REPLY
				not contains $msh_shell / && which -s $msh_shell && msh_shell=$REPLY
				readlink -fs $msh_shell	&& not endswith $REPLY /busybox && msh_shell=$REPLY
				if not so || not is present $msh_shell; then
					echo "$msh_shell does not seem to exist. Please try again."
				elif match $msh_shell *[!$SHELLSAFECHARS]*; then
					print "The path '$msh_shell' contains" \
						"non-shell-safe characters. Try another path."
				elif not can exec $msh_shell; then
					echo "$msh_shell does not seem to be executable. Try another."
				elif not $msh_shell -c $test_modernish; then
					echo "$msh_shell was found unable to run modernish. Try another."
				else
					break
				fi
			else
				# a number was chosen: already tested, so assume good
				break
			fi
		done
		empty $REPLY && exit 2 Aborting.	# user pressed ^D
	endlocal

	print "* Relaunching installer with $msh_shell" ''
	exec env MSH_SHELL=$msh_shell $msh_shell $srcdir/${0##*/} --relaunch
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

# Function to generate 'readonly -f' for bash and yash.
mk_readonly_f() {
	echo "${CCt}readonly -f \\"
	sed -n 's/^[[:blank:]]*\([a-zA-Z_][a-zA-Z_]*\)()[[:blank:]]*{.*/\1/p
		s/^[[:blank:]]*eval '\''\([a-zA-Z_][a-zA-Z_]*\)()[[:blank:]]*{.*/\1/p' \
			$1 |
		grep -Ev '(^showusage$|^_Msh_initExit$|^_Msh_test|^_Msh_have$|^_Msh_tmp)' |
		sort -u |
		paste -sd' ' - |
		fold -sw64 |
		sed "s/^/${CCt}${CCt}/; \$ !s/\$/\\\\/; \$ s/\$/ \\\\/"
	echo "${CCt}${CCt}2>/dev/null"
}

# Function to identify the version of this shell, if possible.
identify_shell() {
	case ${YASH_VERSION+ya}${KSH_VERSION+k}${SH_VERSION+k}${ZSH_VERSION+z}${BASH_VERSION+ba} in
	( ya )	print "* This shell identifies itself as yash version $YASH_VERSION" ;;
	( k )	isset KSH_VERSION || KSH_VERSION=$SH_VERSION
		case $KSH_VERSION in
		( '@(#)MIRBSD KSH '* )
			print "* This shell identifies itself as mksh version ${KSH_VERSION#*KSH }." ;;
		( '@(#)LEGACY KSH '* )
			print "* This shell identifies itself as lksh version ${KSH_VERSION#*KSH }." ;;
		( '@(#)PD KSH v'* )
			print "* This shell identifies itself as pdksh version ${KSH_VERSION#*KSH v}."
			if endswith $KSH_VERSION 'v5.2.14 99/07/13.2'; then
				print "  (Note: many different pdksh variants carry this version identifier.)"
			fi ;;
		( Version* )
			print "* This shell identifies itself as AT&T ksh93 v${KSH_VERSION#V}." ;;
		( * )	print "* WARNING: This shell has an unknown \$KSH_VERSION identifier: $KSH_VERSION." ;;
		esac ;;
	( z )	print "* This shell identifies itself as zsh version $ZSH_VERSION." ;;
	( ba )	print "* This shell identifies itself as bash version $BASH_VERSION." ;;
	( * )	if (eval '[[ -n ${.sh.version+s} ]]') 2>/dev/null; then
			eval 'print "* This shell identifies itself as AT&T ksh v${.sh.version#V}."'
		else
			print "* This is a POSIX-compliant shell without a known version identifier variable."
		fi ;;
	esac
	print "  Modernish detected the following bugs, quirks and/or extra features on it:"
	thisshellhas --show | sort | paste -s -d ' ' - | fold -s -w 78 | sed 's/^/  /'
}

# --- Main ---

case ${1-} in
( --relaunch )
	msh_shell=$MSH_SHELL
	print "* Modernish version $MSH_VERSION, now running on $msh_shell".
	identify_shell ;;
( * )
	print "* Welcome to modernish version $MSH_VERSION."
	identify_shell
	pick_shell_and_relaunch ;;
esac

print "* Running modernish test suite on $msh_shell ..."
(source libexec/modernish/tests/run.sh -qq \
 && print "No bugs in modernish itself were detected.") | sed 's/^/  /'

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
	print "* Warning: this shell has BUG_FNSUBSH, complicating 'use var/setlocal'."
	shellwarning=y
fi
if isset shellwarning; then
	print "  Using this shell as the default shell is possible, but not recommended." \
		"  Modernish itself works around these bug(s), but some modernish scripts" \
		"  that have not implemented relevant workarounds may refuse to run."
fi

if isset BASH_VERSION; then
	print "  Note: bash is good, but much slower than other shells. If performance" \
	      "  is important to you, it is recommended to pick another shell."
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
		if empty $installroot; then
			# Installing in the home directory may not be as straightforward
			# as simply installing in ~/bin. Search $PATH to see if the
			# install prefix should be a subdirectory of ~.
			setlocal p --split=:	# ':' is $PATH separator
				for p in $PATH; do
					startswith $p $srcdir && continue 
					is -L dir $p && can write $p || continue
					if identic $p ~/bin || match $p ~/*/bin
					then  #       ^^^^^             ^^^^^^^ note: tilde expansion, but no globbing
						installroot=${p%/bin}
						return	# exit setlocal
					fi
				done
				installroot=~
				print "* WARNING: $installroot/bin is not in your PATH."
			endlocal
		fi
	fi
	if match $installroot *[!$SHELLSAFECHARS]*; then
		print "The path '$installroot' contains" \
			"non-shell-safe characters. Please try again."
		unset -v installroot
	elif not is present $installroot; then
		if ask_q "$installroot doesn't exist yet. Create it? (y/n)"; then
			mkdir -p $installroot
		else
			unset -v installroot
		fi
	elif not is -L dir $installroot; then
		print "$installroot is not a directory. Please try again."
		unset -v installroot
	fi
done

# zsh is more POSIX compliant if launched as sh, in ways that cannot be
# achieved if launched as zsh; so use a compatibility symlink to zsh named 'sh'
if isset ZSH_VERSION && not endswith $msh_shell /sh; then
	my_zsh=$msh_shell	# save for later
	zsh_compatdir=$installroot/libexec/modernish/zsh-compat
	msh_shell=$zsh_compatdir/sh
else
	unset -v my_zsh zsh_compatdir
fi

# Handler function for 'traverse': install one file or directory.
# Parameter: $1 = full source path for a file or directory.
# TODO: handle symlinks (if/when needed)
install_handler() {
	case ${1#.} in
	( */.* | */_* | */Makefile | *~ | *.bak )
		# ignore these (if directory, prune)
		return 1 ;;
	esac
	if is dir $1; then
		absdir=${1#.}
		destdir=$installroot$absdir
		if not is present $destdir; then
			mkdir $destdir
		fi
	elif is reg $1; then
		relfilepath=${1#./}
		if not contains $relfilepath /; then
			# ignore files at top level
			return 1
		fi
		destfile=$installroot/$relfilepath
		if is present $destfile; then
			exit 3 "Fatal error: '$destfile' already exists, refusing to overwrite"
		fi
		echo -n "- Installing: $destfile "
		if identic $relfilepath bin/modernish; then
			echo -n "(hashbang path: #! $msh_shell) "
			readonly_f=$(mktemp)	# use mktemp from sys/base/mktemp module
			mk_readonly_f $1 >|$readonly_f || exit 1 "can't write to temp file"
			# 'harden sed' aborts program if 'sed' encounters an error,
			# but not if the output direction (>) does, so add a check.
			sed "	1		s|.*|#! $msh_shell|
				/^MSH_SHELL=/	s|=.*|=$msh_shell|
				/^MSH_PREFIX=/	s|=.*|=$installroot|
				/@ROFUNC@/	{	r $readonly_f
							d;	}
			" $1 > $destfile || exit 2 "Could not create $destfile"
			rm -f $readonly_f
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
traverse . install_handler

# Handle README.md specially.
echo "- Installing: $installroot/share/doc/modernish/README.md (not executable)"
cp -p README.md $installroot/share/doc/modernish/
chmod 644 $installroot/share/doc/modernish/README.md

# If we're on zsh, install compatibility symlink.
if isset ZSH_VERSION && isset my_zsh && isset zsh_compatdir; then
	mkdir -p $zsh_compatdir
	print "- Installing zsh compatibility symlink: $msh_shell -> $my_zsh"
	ln -sf $my_zsh $msh_shell
	msh_shell=$my_zsh
fi

print '' "Modernish $MSH_VERSION installed successfully with default shell $msh_shell." \
	"Be sure $installroot/bin is in your \$PATH before starting." \
