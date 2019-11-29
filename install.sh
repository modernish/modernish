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

# request minimal standards compliance
POSIXLY_CORRECT=y; export POSIXLY_CORRECT
std_cmd='case ${ZSH_VERSION+s} in s) emulate sh;; *) (set -o posix) 2>/dev/null && set -o posix;; esac'
eval "$std_cmd"

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
		exec "$MSH_SHELL" "$0" --relaunch "$@" ;;
	esac ;;
esac
case ${opt_D+s} in
( s )	opt_D=$(mkdir -p "$opt_D" && cd "$opt_D" && pwd && echo X) && opt_D=${opt_D%?X} || exit ;;
esac

# find directory install.sh resides in; assume everything else is there too
case $0 in
( */* )	srcdir=${0%/*} ;;
( * )	srcdir=. ;;
esac
srcdir=$(cd "$srcdir" && pwd && echo X) || exit
srcdir=${srcdir%?X}
cd "$srcdir" || exit

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
use var/shellquote
use var/string/append
use var/string/trim
use sys/base/mktemp
use sys/base/which
use sys/cmd/extern
use sys/cmd/harden
use sys/term/readkey

# abort program if any of these commands give an error
# (the default error condition is '> 0', exit status > 0;
# for some commands, such as grep, this is different)
# also make sure the system default path is used to find them (-p)
harden -p cat
harden -p cd
harden -p -t mkdir
harden -p chmod
harden -p ln
harden -p -e '> 1' LC_ALL=C grep
harden -p sed
harden -p sort
harden -p paste
harden -p fold
harden -p -e '> 4' tput


# End of modernish initialisation; from now on, it's a proper modernish script.
#
# (Does the script below seem like it makes lots of newbie mistakes with not
# quoting variables and glob patterns? Think again! Using the 'safe' module
# disables field splitting and globbing, along with all their hazards: most
# variable quoting is unnecessary and glob patterns can be passed on to
# commands such as 'match' without quoting. The new modernish loop construct
# is used to split or glob values instead, without enabling field splitting
# or globbing at any point in the code. No quoting headaches here!)

# Validate a shell path input by a user.
validate_msh_shell() {
	str empty $msh_shell && return 1
	if not which -s $msh_shell; then
		putln "$msh_shell not found or not executable. Please try again."
		return 1
	fi
	msh_shell=$REPLY  # use path returned by 'which -s'
	if str match $msh_shell *[!$SHELLSAFECHARS]*; then
		putln "The path '$msh_shell' contains" \
			"non-shell-safe characters. Try another path."
		return 1
	elif not str eq $$ $(exec $msh_shell -c "$std_cmd; command . \"\$0\" || echo BUG" $MSH_AUX/fatal.sh 2>&1); then
		putln "$msh_shell was found unable to run modernish. Try another."
		return 1
	fi
} >&2

# function that lets the user choose a shell from /etc/shells or provide their own path,
# verifies that the shell can run modernish, then relaunches the script with that shell
pick_shell_and_relaunch() {
	clear_eol=$(tput el)	# clear to end of line

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
yesexpr=$(PATH=$DEFPATH command locale yesexpr 2>/dev/null) && trim yesexpr \" || yesexpr=^[yY]
noexpr=$(PATH=$DEFPATH command locale noexpr 2>/dev/null) && trim noexpr \" || noexpr=^[nN]
ask_q() {
	REPLY=''
	put "$1 (y/n) "
	readkey -E "($yesexpr|$noexpr)" REPLY || exit 2 Aborting.
	putln $REPLY
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
				str begin $p $srcdir && continue
				is -L dir $p && can write $p || continue
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
	if not is present ${opt_D-}$installroot; then
		if isset opt_D || { not isset opt_n && ask_q "$installroot doesn't exist yet. Create it?"; }; then
			mkdir -p ${opt_D-}$installroot
		elif isset opt_n; then
			exit 1 "$installroot doesn't exist."
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
	# Make sure it's an absolute path
	installroot=$(cd ${opt_D-}$installroot && pwd && echo X) || exit
	installroot=${installroot%?X}
	isset opt_D && installroot=${installroot#"$opt_D"}
	if str match $installroot *[!$SHELLSAFECHARS]*; then
		putln "The path '$installroot' contains non-shell-safe characters. Please try again." | fold -s >&2
		if isset opt_n || isset opt_D; then
			exit 1
		fi
		unset -v installroot opt_d
		continue
	fi
	if str begin $(cd ${opt_D-}$installroot && pwd -P)/ $(cd $srcdir && pwd -P)/; then
		putln "The path '${opt_D-}$installroot' is within the source directory '$srcdir'. Choose another." | fold -s >&2
		isset opt_n && exit 1
		unset -v installroot opt_d
		continue
	fi
done

# --- Begin installation ---

# zsh is more POSIX compliant if launched as sh, in ways that cannot be
# achieved if launched as zsh; so use a compatibility symlink to zsh named 'sh'
if isset ZSH_VERSION && not str end $msh_shell /sh; then
	zsh_compatdir=$installroot/lib/modernish/aux/zsh
	mkdir -p ${opt_D-}$zsh_compatdir
	ln -sf $msh_shell ${opt_D-}$zsh_compatdir/sh
	msh_shell=$zsh_compatdir/sh
	putln "- Installed zsh compatibility symlink: ${opt_D-}$zsh_compatdir/sh -> $msh_shell"
fi

# Traverse through the source directory, installing files as we go.
LOOP find F in . -path */[._]* -prune -or -type f -iterate; DO
	if is_ignored $F; then
		continue
	fi
	F=${F#./}
	destfile=${opt_D-}$installroot/$F
	case $F in
	( bin/modernish )
		mktemp -dsC; tmpdir=$REPLY	# use mktemp with auto-cleanup from sys/base/mktemp module
		# paths with spaces do occasionally happen, so make sure the assignments work
		shellquote -P defpath_q=${_need_tput_wrapper:+$installroot/lib/modernish/aux/tputw:}${_orig_DEFPATH}
		putln "DEFPATH=$defpath_q" >$tmpdir/DEFPATH.sh || die
		mk_readonly_f $F >$tmpdir/readonly_f.sh || die
		install_file $F $destfile \
		"	1		s|.*|#! $msh_shell|
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
	( lib/modernish/aux/tputw/tput )
		isset _need_tput_wrapper || continue
		systput=$(PATH=${_orig_DEFPATH}; extern -v tput) || die "internal error: tput gone?"
		shellquote -P systput
		install_file $F $destfile \
		"	1		s|.*|#! $msh_shell|
			/^systput=/	s|=.*|=$systput|
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
