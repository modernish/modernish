#! /bin/sh

# Interactive installer for modernish.
# https://github.com/modernish/modernish
#
# This installer is itself an example of a modernish script (from '. modernish' on).
# For more conventional examples, see share/doc/modernish/examples
#
# --- begin license ---
# Copyright (c) 2019 Martijn Dekker <martijn@inlv.org>, Groningen, Netherlands
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

case ${MSH_VERSION+s} in
( s )	echo "The modernish installer cannot be run by modernish itself." >&2
	exit 128 ;;
esac

# find my own absolute and physical directory path
unset -v CDPATH
case $0 in
( */* )	srcdir=${0%/*} ;;
( * )	srcdir=. ;;
esac
case $srcdir in
( */* | [!+-]* | [+-]*[!0123456789]* )
	srcdir=$(cd -- "$srcdir" && pwd -P && echo X) ;;
( * )	srcdir=$(cd "./$srcdir" && pwd -P && echo X) ;;
esac || exit
srcdir=${srcdir%?X}
cd "$srcdir" || exit

# put the shell in standards mode
. lib/modernish/aux/std.sh

# ensure sane default permissions
umask 022

usage() {
	echo "usage: $0 [ -n ] [ -s SHELL ] [ -f ] [ -P PATH ] [ -d INSTALLROOT ] [ -D PREFIX ]"
	echo "	-n: non-interactive operation"
	echo "	-s: specify default shell to execute modernish"
	echo "	-f: force unconditional installation on specified shell"
	echo "	-P: specify alternative DEFPATH (be careful!)"
	echo "	-d: specify root directory for installation"
	echo "	-D: extra destination directory prefix (for packagers)"
	exit 1
} 1>&2

# parse options
unset -v opt_relaunch opt_n opt_d opt_s opt_f opt_D DEFPATH
case ${1-} in
( --relaunch )
	opt_relaunch=''
	shift ;;
( * )	unset -v MSH_SHELL ;;
esac
while getopts 'ns:fP:d:D:' opt; do
	case $opt in
	( \? )	usage ;;
	( n )	opt_n='' ;;
	( s )	opt_s=$OPTARG ;;
	( f )	opt_f='' ;;
	( P )	DEFPATH=$OPTARG ;;
	( d )	opt_d=$OPTARG ;;
	( D )	opt_D=$OPTARG ;;
	esac
done
case $((OPTIND - 1)) in
( $# )	;;
( * )	usage ;;
esac

# validate options
case ${opt_s+s} in
( s )	OPTARG=$opt_s
	opt_s=$(command -v "$opt_s")
	if ! test -x "$opt_s"; then
		echo "$0: shell not found: $OPTARG" >&2
		exit 1
	fi
	case ${MSH_SHELL-} in
	( "$opt_s" ) ;;
	( * )	MSH_SHELL=$opt_s
		export MSH_SHELL
		echo "Relaunching ${0##*/} with $MSH_SHELL..." >&2
		exec "$MSH_SHELL" "$srcdir/${0##*/}" --relaunch "$@" ;;
	esac ;;
esac
case ${opt_D+s} in
( s )	mkdir -p -- "$opt_D" || exit
	# ensure destdir is absolute and physical
	case $opt_D in
	( */* | [!+-]* | [+-]*[!0123456789]* )
		opt_D=$(cd -- "$opt_D" && pwd -P && echo X) ;;
	( * )	opt_D=$(cd "./$opt_D" && pwd -P && echo X) ;;
	esac || exit
	opt_D=${opt_D%?X} ;;
esac

# determine and/or validate DEFPATH
. lib/_install/defpath.sh || exit
export DEFPATH

# find a compliant POSIX shell
case ${MSH_SHELL-} in
( '' )	. lib/_install/goodsh.sh || exit
	case ${opt_n+n} in
	( n )	# If we're non-interactive, relaunch early so that our shell is known.
		echo "Relaunching ${0##*/} with $MSH_SHELL..." >&2
		exec "$MSH_SHELL" "$srcdir/${0##*/}" --relaunch "$@" ;;
	esac
	case $(command . lib/modernish/aux/fatal.sh || echo BUG) in
	( "${PPID:-no_match_on_no_PPID}" ) ;;
	( * )	echo "Bug attack! Abandon shell!" >&2
		echo "Relaunching ${0##*/} with $MSH_SHELL..." >&2
		exec "$MSH_SHELL" "$srcdir/${0##*/}" "$@" ;;	# no --relaunch or we'll skip the menu
	esac ;;
esac

# load modernish and some modules
. bin/modernish
use safe				# IFS=''; set -f -u -C
use var/arith/cmp			# arithmetic comparison shortcuts: eq, gt, etc.
use var/loop/find
use var/string/append
use sys/base/mktemp
use sys/base/readlink
use sys/base/which
use sys/cmd/extern
use sys/cmd/harden

# abort program if any of these commands give an error
# (the default error condition is '> 0', exit status > 0;
# for some commands, such as grep, this is different)
# also make sure the system default path is used to find them (-p)
harden -p cat
harden -p -t mkdir
harden -p chmod
harden -p ln
harden -p -e '> 1' LC_ALL=C grep
harden -p sed
harden -p sort
harden -p paste
harden -p fold -w ${COLUMNS:-80}  # make 'fold' use window size by default

# (Does the script below seem like it makes lots of newbie mistakes with not
# quoting variables and glob patterns? Think again! Using the 'safe' module
# disables field splitting and globbing, along with all their hazards: most
# variable quoting is unnecessary and glob patterns can be passed on to
# commands such as 'match' without quoting. The new modernish loop construct
# is used to split or glob values instead, without enabling field splitting
# or globbing at any point in the code. No quoting headaches here!

# (style note: modernish library functions never have underscores or capital
# letters in them, so using underscores or capital letters is a good way to
# avoid potential conflicts with future library functions, as well as an
# easy way for readers of your code to tell them apart.)

# Validate a shell path input by a user.
validate_msh_shell() {
	str empty $msh_shell && return 1
	_msh_shell=$(which -q $msh_shell) || {
		putln "$msh_shell not found or not executable. Please try again."
		return 1
	}
	if str match $msh_shell *[!$SHELLSAFECHARS]*; then
		putln "The path '$msh_shell' contains" \
			"non-shell-safe characters. Try another path."
		return 1
	elif not str eq $$ $(exec $msh_shell -c '. "$1" && command . "$2" || echo BUG' \
				$msh_shell $MSH_AUX/std.sh $MSH_AUX/fatal.sh 2>&1)
	then
		putln "$msh_shell was found unable to run modernish. Try another."
		return 1
	fi
} >&2

# function that lets the user choose a shell from /etc/shells or provide their own path,
# verifies that the shell can run modernish, then relaunches the script with that shell
pick_shell_and_relaunch() {
	{ clear_eol=$(tput el || tput ce); } 2>/dev/null	# clear to end of line

	# find shells, eliminating non-compatible shells
	shells_to_test=$(
		{
			which -aq sh ash dash gwsh zsh5 zsh yash bash ksh ksh93 lksh mksh oksh pdksh
			if is -L reg /etc/shells && can read /etc/shells; then
				grep -E '/([bdy]?a|gw|pdk|[mlo]?k|z)?sh[0-9._-]*$' /etc/shells
			fi
		} | sort -u
	)
	valid_shells=''
	LOOP for --split=$CCn msh_shell in $shells_to_test; DO
		put "${CCr}Testing shell $msh_shell...$clear_eol"
		validate_msh_shell 2>/dev/null && append --sep=$CCn valid_shells $msh_shell
	DONE
	if str empty $valid_shells; then
		putln "${CCr}No POSIX-compliant shell found. Please specify one.$clear_eol"
		msh_shell=
		while not validate_msh_shell; do
			put "Shell command name or path: "
			read msh_shell || exit 2 "Aborting."
		done
	else
		putln "${CCr}Please choose a default shell for executing modernish scripts.$clear_eol" \
			"Either pick a shell from the menu, or enter the command name or path" \
			"of another POSIX-compliant shell at the prompt."
		PS3='Shell number, command name or path: '
		LOOP select --split=$CCn msh_shell in $valid_shells; DO
			if str empty $msh_shell; then
				if str isint $REPLY; then
					putln "Out of range." >&2
					continue
				fi
				# a path or command instead of a number was given
				msh_shell=$REPLY
				validate_msh_shell && break
			else
				# a number was chosen: already tested, so assume good
				break
			fi
		DONE || exit 2 "Aborting."  # user pressed ^D
	fi

	putln "* Relaunching installer with $msh_shell" ''
	export MSH_SHELL=$msh_shell
	exec $msh_shell $srcdir/${0##*/} --relaunch "$@"
}

# Simple function to ask a question of a user.
yesexpr=$(PATH=$DEFPATH command locale yesexpr 2>/dev/null) && yesexpr="($yesexpr)|^[yY]" || yesexpr='^[yY]'
noexpr=$(PATH=$DEFPATH command locale noexpr 2>/dev/null) && noexpr="($noexpr)|^[nN]" || noexpr='^[nN]'
ask_q() {
	REPLY=''
	while not str ematch $REPLY "$yesexpr|$noexpr"; do
		put "$1 (y/n) "
		read -r REPLY || exit 2 'Aborting.'
	done
	str ematch $REPLY $yesexpr
}

# Function to generate arguments for 'unalias' for interactive shells and 'readonly -f' for bash and yash.
mk_readonly_f() {
	sed -n 's/^[[:blank:]]*\([a-zA-Z_][a-zA-Z_]*\)()[[:blank:]]*{.*/\1/p
		s/^[[:blank:]]*eval '\''\([a-zA-Z_][a-zA-Z_]*\)()[[:blank:]]*{.*/\1/p' \
			$1 |
		grep -Ev '(^echo$|^_Msh_initExit$|^_Msh_test|^_Msh_tmp)' |
		sort -u |
		paste -sd' ' - |
		fold -sw64 |
		sed "s/^/${CCt}${CCt}/; \$ !s/\$/\\\\/"
}

# Helper function to install one file and report its installation.
# Usage: install_file SRC DEST [ SEDSCRIPT ]
install_file() {
	is present $2 && exit 3 "Error: '$2' already exists, refusing to overwrite"
	is dir ${2%/*} || mkdir -p ${2%/*}
	case $# in
	( 2 )	cat $1 ;;
	( 3 )	sed $3 $1 ;;
	esac > $2 || die "can't create $2"
	read -r hb < $2 || die "can't read from $2"
	if str begin $hb '#!' && hb=${hb#*/} && can exec /${hb%%[$WHITESPACE]*}; then
		chmod +x $2
		putln "- Installed: $2 (hashbang path: /$hb)"
	else
		putln "- Installed: $2"
	fi
}

# Define a function to check if a file is to be ignored/skipped.
if command -v git >/dev/null && command git check-ignore --quiet foo~ 2>/dev/null; then
	# If we're installing from git repo, make is_ignored() ask git to check against .gitignore.
	harden -f is_ignored -e '>1' git check-ignore --quiet --
else
	is_ignored() case $1 in (*~ | *.bak | *.orig | *.rej) ;; (*) return 1;; esac
fi


# --- Main ---

if isset opt_n || isset opt_s || isset opt_relaunch; then
	msh_shell=$MSH_SHELL
	validate_msh_shell || exit
	MSH_SHELL=$msh_shell
	putln "* Modernish version $MSH_VERSION, now running on $msh_shell".
	. $MSH_AUX/id.sh
else
	putln "* Welcome to modernish version $MSH_VERSION."
	. $MSH_AUX/id.sh
	pick_shell_and_relaunch "$@"
fi

putln "* Running modernish test suite on $msh_shell ..."
if $msh_shell bin/modernish --test -eqq; then
	putln "* Tests passed. No bugs in modernish were detected."
elif isset opt_n && not isset opt_f; then
	putln "* ERROR: modernish has some bug(s) in combination with this shell." \
	      "         Add the '-f' option to install with this shell anyway." >&2
	exit 1
else
	putln "* WARNING: modernish has some bug(s) in combination with this shell." \
	      "           Run 'modernish --test' after installation for more details."
fi

if isset BASH_VERSION && str match $BASH_VERSION [34].*; then
	putln "  Note: bash before 5.0 is much slower than other shells. If performance" \
	      "  is important to you, it is recommended to pick another shell."
fi

if not isset opt_n && not isset opt_f; then
	ask_q "Are you happy with $msh_shell as the default shell?" \
	|| pick_shell_and_relaunch ${opt_d+-d$opt_d} ${opt_D+-D$opt_D}
fi

while not isset installroot; do
	if not isset opt_n && not isset opt_d; then
		putln "* Enter the directory prefix for installing modernish."
	fi
	if isset opt_d; then
		installroot=$opt_d
	elif isset opt_D || { is -L dir /usr/local && can write /usr/local; }; then
		if isset opt_n; then
			installroot=/usr/local
		else
			putln "  Just press 'return' to install in /usr/local."
			put "Directory prefix: "
			read -r installroot || exit 2 Aborting.
			str empty $installroot && installroot=/usr/local
		fi
	else
		if isset opt_n; then
			installroot=
		else
			putln "  Just press 'return' to install in your home directory."
			put "Directory prefix: "
			read -r installroot || exit 2 Aborting.
		fi
		if str empty $installroot; then
			# Installing in the home directory may not be as straightforward
			# as simply installing in ~/bin. Search $PATH to see if the
			# install prefix should be a subdirectory of ~.
			# Note: '--split=:' splits $PATH on ':' without activating split within the loop.
			LOOP for --split=: p in $PATH; DO
				str begin $p / || continue
				is -L dir $p && can write $p || continue
				str begin $(chdir -P -- ${opt_D-}/$p; put $PWD/) $srcdir/ && continue
				if str eq $p ~/bin || str match $p ~/*/bin
				then #	     ^^^^^		   ^^^^^^^ note: tilde expansion, but no globbing
					installroot=${p%/bin}
					break
				fi
			DONE
			if str empty $installroot; then
				installroot=~
				putln "* WARNING: $installroot/bin is not in your PATH."
			fi
		fi
	fi
	# Canonicalise.
	if isset opt_D; then
		readlink -s -m $opt_D/$installroot || exit 128 'internal error 1'
		str eq $REPLY $opt_D$installroot || putln "Canonicalising '$installroot' to '${REPLY#"$opt_D"}'." | fold -s
		if not str begin $REPLY $opt_D; then
			putln "Canonicalised path '$REPLY' is not within destdir '$opt_D'. Please try again." | fold -s >&2
			isset opt_n && exit 1
			unset -v installroot opt_d
			continue
		fi
		installroot=${REPLY#"$opt_D"}
	else
		readlink -s -m $installroot || exit 128 'internal error 2'
		str eq $REPLY $installroot || putln "Canonicalising '$installroot' to '$REPLY'." | fold -s
		installroot=$REPLY
	fi
	# Verify existence.
	if str begin $REPLY/ $srcdir/; then
		putln "The path '${opt_D-}$installroot' is within the source directory '$srcdir'. Choose another." | fold -s >&2
		isset opt_n && exit 1
		unset -v installroot opt_d
		continue
	elif not is present ${opt_D-}$installroot; then
		if isset opt_D || { not isset opt_n && ask_q "${opt_D-}$installroot doesn't exist yet. Create it?"; }; then
			mkdir -p ${opt_D-}$installroot
		elif isset opt_n; then
			exit 1 "${opt_D-}$installroot doesn't exist."
		else
			unset -v installroot opt_d
			continue
		fi
	elif not is -L dir ${opt_D-}$installroot; then
		putln "${opt_D-}$installroot is not a directory. Please try again." | fold -s >&2
		isset opt_n && exit 1
		unset -v installroot opt_d
		continue
	fi
	# Check for shell-safe path.
	if str match $installroot *[!$SHELLSAFECHARS]*; then
		putln "The path '$installroot' contains non-shell-safe characters. Please try again." | fold -s >&2
		if isset opt_n || isset opt_D; then
			exit 1
		fi
		unset -v installroot opt_d
		continue
	fi
done

# zsh is more POSIX compliant if launched as sh, in ways that cannot be
# achieved if launched as zsh; so use a compatibility symlink to zsh named 'sh'
if isset ZSH_VERSION && not str end $msh_shell /sh; then
	my_zsh=$msh_shell	# save for later
	zsh_compatdir=$installroot/lib/modernish/aux/zsh
	msh_shell=$zsh_compatdir/sh
	mkdir -p ${opt_D-}$zsh_compatdir
	putln "- Installing zsh compatibility symlink: ${opt_D-}$msh_shell -> $my_zsh"
	ln -sf $my_zsh ${opt_D-}$msh_shell
fi

# --- Begin installation ---

mktemp -dsC; tmpdir=$REPLY	# use mktemp with auto-cleanup from sys/base/mktemp module

# Traverse through the source directory, installing files as we go.
LOOP find F in . \
	'(' -path ./_* -or -path */.* -or -path ./lib/_install ')' -prune \
	-or -type f -iterate
DO
	if is_ignored $F; then
		continue
	fi
	F=${F#./}
	destfile=${opt_D-}$installroot/$F
	case $F in
	( bin/modernish )
		# paths with spaces do occasionally happen, so make sure the assignments work
		hashbang="#! $msh_shell"
		isset BASH_VERSION && hashbang="$hashbang -p"  # don't inherit exported functions in portable-form scripts
		shellquote -P defpath_q=$DEFPATH
		putln "DEFPATH=$defpath_q" >$tmpdir/DEFPATH.sh || die
		mk_readonly_f $F >$tmpdir/readonly_f.sh || die
		install_file $F $destfile \
		"	1		s|.*|$hashbang|
			/^MSH_PREFIX=/	s|=.*|=$installroot|
			/_install\\/goodsh\\.sh\"/  s|.*|MSH_SHELL=$msh_shell|
			/_install\\/defpath\\.sh\"/ {
						r $tmpdir/DEFPATH.sh
						d;	}
			/@ROFUNC@/	{	r $tmpdir/readonly_f.sh
						d;	}
			/^#readonly MSH_/ {	s/^#//
						s/[[:blank:]]*#.*//;	}
			/^[[:blank:]]*\"Not installed. Run install\\.sh/ d
		"
		;;
	( */* )
		install_file $F $destfile
		;;
	( *.md | [$ASCIIUPPER][$ASCIIUPPER]* )
		# a top-level documentation file
		install_file $F ${opt_D-}$installroot/share/doc/modernish/$F
		;;
	# ignore other files at top level
	esac
DONE

putln '' "Modernish $MSH_VERSION installed successfully with default shell $msh_shell." \
	"Be sure $installroot/bin is in your \$PATH before starting." \
