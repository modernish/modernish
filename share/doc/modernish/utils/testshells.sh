#! /usr/bin/env modernish
#! use safe -k
#! use sys/base/mktemp	# for modernish mktemp (note: -C = auto-cleanup!)
#! use sys/cmd/harden
#! use var/local
#! use var/loop
#! use var/string	# for 'trim', 'replacein'
#! use var/shellquote

# This is a general-purpose shell compatibility testing tool for trying out
# any command or script on multiple shells. The list of shells to test is kept
# in $MSH_CONFIG/shellsrc (.config/modernish/shellsrc in your home directory).
#
# testshells accepts a shell-like command option syntax with '-c' to run a
# command or a path to run a script. '-P' activates POSIX compatibility mode
# for the tested shells where possible. '-t' times execution for each shell.
# After each command or script is run, its exit status is reported.
#
# When you first run the program, testshells attempts to gather a list of
# Bourne/POSIX-derived shells on your system. It then writes shellsrc and
# offers to let you edit the file before proceeding.
#
# Each path in shellsrc may be edited either to add arguments to invoke the
# shell with those arguments, or to use shell glob patterns so that one line
# may resolve to multiple shells (in which case arguments are not possible).
#
# --- begin licence ---
# Copyright (c) 2020-2022 Martijn Dekker <martijn@inlv.org>
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
# --- end licence ---

# ___ parse and validate options _____________________________________________

showusage() {
	putln "\
Usage:	${ME##*/} [ -t ] [ -P ] SCRIPTFILE [ ARGUMENT ... ]
	${ME##*/} [ -t ] [ -P ] -c COMMANDS [ ME_NAME [ ARGUMENT ... ] ]
	-t: time script execution
	-c: specify script commands directly
	-P: run script in POSIX mode (where supported)"
}
unset -v opt_t opt_c opt_P
while getopts ':tcP' opt; do
	case $opt in
	( \? )	exit -u 1 "Invalid option: -$OPTARG" ;;
	( t )	opt_t='' ;;
	( c )	opt_c='' ;;
	( P )	opt_P='' ;;
	esac
done
shift $(($OPTIND - 1))

let $# || exit -u 2 "Specify one script to test, with optional arguments."
script=$1
shift
if not isset opt_c; then
	if not str in $script '/' && not is present $script; then
		# If file is not present in current dir, do a $PATH search
		LOOP for --split=':' dir in $PATH; DO
			str empty $dir && continue
			if is -L reg $dir/$script && can read $dir/$script; then
				script=$dir/$script
				break
			fi
		DONE
	fi
	is -L reg $script || exit 2 "Not found or not a regular file: $script"
	can read $script || exit 2 "No read permission: $script"
fi
# Avoid script name/path being processed as option.
# Due to a longstanding FreeBSD sh bug we can't use '--' after '-c', so prefix a space or './' instead.
# Ref.: https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=220587
if str begin $script '-'; then
	isset opt_c && script=" $script" || script=./$script
fi

# ___ init ___________________________________________________________________

# harden certain utilities we use
harden -p ln
harden -p mkdir
harden -p printf
harden -p -e '>4' tput
if isset opt_t && not thisshellhas time; then
	# harden external 'time' command against command not executable (126) or not found (127)
	harden -p -e '==126 || ==127' time
fi

# disable core dumps in case tested shells crash
ulimit -c 0 2>/dev/null

# determine terminal capabilities
if is onterminal stdout && tReset=$(tput sgr0 2>/dev/null); then
	tBlue=$(tput setaf 4 2>/dev/null || tput smul)
	tGreen=$(tput setaf 2 2>/dev/null)
	tRed=$(tput setaf 1 2>/dev/null || tput bold)
else
	tReset=
	tBlue=
	tGreen=
	tRed=
fi

# find shells
shellsfile=$MSH_CONFIG/shellsrc
if not is -L reg $shellsfile; then
	putln "shellsrc not found; initialising it. Welcome to testshells."
	# run all this in a subshell using some extra modules & hardened commands we don't need elsewhere
	(
		use sys/base/which
		use sys/base/rev
		use sys/cmd/extern
		harden -p -e '> 1' grep
		harden -p LC_COLLATE=C sort

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

		mkdir -p -m700 $MSH_CONFIG
		put "Gathering shells into $shellsfile... "
		putln "# List of shells for testshells.sh. Each line supports either glob patterns for" \
		      "# resolving to multiple shells, or arguments and shell grammar to add options." >|$shellsfile
		{
			which -aq sh ash dash gwsh zsh5 zsh yash bash ksh ksh93 lksh mksh oksh pdksh
			if is -L reg /etc/shells && can read /etc/shells; then
				grep -E '/([bdy]?a|gw|pdk|[mlo]?k|z)?sh[0-9._-]*$' /etc/shells
			fi
		} | rev | sort -u | rev >>$shellsfile
		putln "Done." "Edit that file to your liking, or delete it to search again."
		if ask_q "Edit it now?"; then
			editor=${VISUAL:-${EDITOR:-vi}}
			# First try the command unchanged, in case the path contains whitespace.
			if extern -v $editor >/dev/null; then
				extern $editor $shellsfile
			else
				# Try splitting it, as it may contain arguments.
				LOCAL --split -- $editor; BEGIN
					extern "$@" $shellsfile
				END
			fi || exit 1 "Drat. Your editor failed."
		fi
		putln "Commencing regular operation."
	) || exit
fi

# Create temporary directory for 'sh' symlinks.
mktemp -dsCC '/tmp/POSIXMODE_'		# 2x -C = clean up temp dir even on SIGINT (Ctrl-C)
posix_sh_dir=$REPLY

# Allow each test script to know what shell is running it.
export shell

# ___ function definitions ___________________________________________________

# Parse shell grammar in $shell, check if the command is a shell,
# and find out how to set its POSIX mode if requested.
check_shell() {
	# Block shenanigans: disallow ; | & < > (including || &&).
	if str match $shell '*[;|&<>]*'; then
		return 1
	fi

	# Check/parse syntax, storing parsed arguments into positional parameters.
	(PATH=/dev/null; eval ": $shell") || return 1
	eval "set -- $shell"

	# Require absolute paths (starting with / or ~).
	if not str match "${1-}" [/~]?*; then
		return 1
	fi

	# Check if this is a shell by attempting to run 'echo'.
	hi=$(exec "$@" -c 'echo hi' 2>/dev/null)
	if not str eq $hi 'hi'; then
		return 1
	fi

	# If we don't need to set POSIX mode, we're now done.
	if not isset opt_P; then
		return
	fi

	# Figure out how to set POSIX mode for this shell, storing result back in $shell.
	# For zsh, the '--emulate' option must come before any other arguments,
	# so we need to insert $args between the path and any custom arguments.
	for args in \
		'-o posix' \
		'--emulate sh -o POSIX_ARGZERO'
	do
		testme=$(
			IFS=' '			# field split on space within this comsub
			s=$1			# save shell path
			shift			# remove shell path
			set -- "$s" $args "$@"	# prepend shell path and field-splitted args
			shellquoteparams	# quote each arg for eval
			put "$@"		# output quoted args separated by spaces
		)
		if str eq $(eval "$testme -c 'echo hi'" 2>/dev/null) 'hi'; then
			shell=$testme
			return
		fi
	done

	# We can't set POSIX mode with a command line argument, so use a symlink
	# called 'sh' in hopes the shell will notice it is being launched as 'sh'.
	# As of 2019, the only shell known to need this is zsh <= 5.4.2, but it doesn't hurt others.
	str end $1 /sh && return
	posix_sh=$1
	replacein -a posix_sh '/' '|'
	mkdir $posix_sh_dir/$posix_sh
	posix_sh=$posix_sh_dir/$posix_sh/sh
	ln -s $1 $posix_sh
	shift				# remove original shell path
	set -- $posix_sh "$@"		# replace path to symlink
	LOCAL IFS=' '; BEGIN
		shellquoteparams	# re-quote arguments for 'eval'
		shell="$*"		# IFS=' ' makes "$*" use space as separator
	END
}

# ___ main ___________________________________________________________________

while read shell <&8; do
	shell=${shell%%[ $CCt]#*} 	# remove comments
	trim shell			# remove leading/trailing whitespace

	# Resolve glob pattern if [?* present, by temporarily enabling global pathname expansion.
	# If it resolves (i.e., changes), quote each result for eval; no arguments are possible.
	if str match $shell *[[?*]*; then
		set +o noglob
		set -- $shell		# store glob results in positional parameters (PPs)
		set -o noglob
		if let "$# > 1" || str ne $1 $shell; then
			shellquoteparams
		fi
	else
		set -- $shell
	fi

	# Now there is either one PP containing a shell path with possible arguments or
	# other shell grammar, or multiple PPs with quoted shell paths. Loop through them.
	for shell do
		check_shell || continue

		# Print header.
		printf '%s> %s%s%s\n' "$tGreen" "$tBlue" $shell "$tReset"

		# Run script with current shell.
		(
			isset opt_P && export POSIXLY_CORRECT=y || unset -v POSIXLY_CORRECT
			eval "${opt_t+time} $shell ${opt_c+-c}" '"$script" "$@"' 8<&-
		)

		# Report exit status.
		e=$?
		let e==0 && ec=$tGreen || ec=$tRed
		printf '%s%s[exit %s%d%s]%s\n' "$tReset" "$tBlue" "$ec" $e "$tBlue" "$tReset"
	done
done 8<$shellsfile
