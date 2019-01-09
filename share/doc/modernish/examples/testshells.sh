#! /usr/bin/env modernish
#! use safe
#! use sys/cmd/harden
#! use var/local
#! use var/loop
#! use var/unexport
#! use var/string	# for 'trim', 'replacein'
harden -p -e '== 2 || > 4' tput
harden -p printf

# testshells: test any command or script on multiple POSIX shells.

# parse options
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
			if is -L reg $dir/$script && can read $dir/$script; then
				script=$dir/$script
				break
			fi
		DONE
	fi
	is -L reg $script || exit 2 "Not found or not a regular file: $script"
	can read $script || exit 2 "No read permission: $script"
fi

if isset opt_t && not thisshellhas time; then
	# harden external 'time' command against command not executable (126) or not found (127)
	harden -e '==126 || ==127' time
fi

# determine terminal capabilities (none if stdout (FD 1) is not on a terminal)
if is onterminal 1; then
	if tReset=$(tput sgr0 2>/dev/null); then
		# tput uses terminfo codes (most un*x systems)
		tBlue=$(tput setaf 4 2>/dev/null || tput smul)
		tGreen=$(tput setaf 2 2>/dev/null)
		tRed=$(tput setaf 1 2>/dev/null || tput bold)
	elif tReset=$(tput me 2>/dev/null); then
		# tput uses termcap codes (FreeBSD)
		tBlue=$(tput AF 4 2>/dev/null || tput us)
		tGreen=$(tput AF 2 2>/dev/null)
		tRed=$(tput AF 1 2>/dev/null || tput md)
	else
		# no known terminal capabilities
		tReset=
		tBlue=
		tGreen=
		tRed=
	fi
else
	# stdout is not on a terminal
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
		use sys/term/readkey
		harden -p -e '> 1' grep
		harden -pt mkdir
		harden -p LC_COLLATE=C sort

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

		mkdir -p -m700 $MSH_CONFIG
		put "Gathering shells into $shellsfile... "
		putln "# List of shells for testshells.sh. Arguments and shell grammar are supported." >|$shellsfile
		{
			which -q -a sh ash bash dash yash zsh zsh5 ksh ksh93 pdksh mksh lksh oksh
			# supplement 'which' results with any additional shells from /etc/shells
			if can read /etc/shells; then
				grep -E '/([bdy]?a|pdk|[mlo]?k|z)?sh[0-9._-]*$' /etc/shells
			fi
		} | rev | sort -u | rev >>$shellsfile
		putln "Done." "Edit that file to your liking, or delete it to search again."
		if ask_q "Edit it now?"; then
			# $VISUAL or $EDITOR may contain arguments; must split
			LOCAL --split -- ${VISUAL:-${EDITOR:-vi}}; BEGIN
				"$@" $shellsfile
			END || exit 1 "Drat. Your editor failed."
		fi
		putln "Commencing regular operation."
	) || exit
fi

# parse shell grammar in $1, check if the command is a shell,
# and find out how to set its POSIX mode if requested
unset -v posix_sh_dir
is_shell() {
	let "$# > 0" || return 1
	str match $1 '*[;|&<>]*' && return 1  # block shell grammar shenanigans
	(set -e; PATH=/dev/null; eval ": $1") && eval "set -- $1" || return 1
	str match "${1-}" [/~]?* && can exec "${1-}" || return 1  # require absolute paths
	str id $(exec "$@" -c 'echo hi' 2>/dev/null) 'hi' || return 1
	posix_args=
	posix_sh=
	if isset opt_P && not str match $1 */sh; then
		for args in \
			'-o posix' \
			'--emulate sh -o POSIX_ARGZERO'
		do
			if str id $(eval "exec \"\$@\" $args -c 'echo hi'" 2>/dev/null) 'hi'; then
				posix_args=$args
				break
			fi
		done
		not str empty $posix_args && return 0

		# We can't set POSIX mode with a command line argument, so use a symlink
		# called 'sh' in hopes the shell will notice it is being launched as 'sh'.
		# Create a temporary directory for these symlinks, with a subdirectory for
		# each shell, named after the pathname with all '/' changed to '|'.
		if not isset posix_sh_dir; then
			use sys/base/mktemp		# for modernish mktemp (note: -C = auto-cleanup!)
			harden -p ln
			harden -p mkdir

			mktemp -dsCC '/tmp/POSIXMODE_'	# 2x -C = delete temp dir even on SIGINT (Ctrl-C)
			posix_sh_dir=$REPLY
		fi
		posix_sh=$1
		replacein -a posix_sh '/' '|'
		mkdir $posix_sh_dir/$posix_sh
		posix_sh=$posix_sh_dir/$posix_sh/sh
		ln -s $1 $posix_sh
		shift
		set -- $posix_sh "$@"
		LOCAL IFS=' '; BEGIN	# IFS=' ' makes "$*" use space as separator
			shellquoteparams
			shell="$*"
		END
	fi
}

isset opt_P && export POSIXLY_CORRECT=y || unexport POSIXLY_CORRECT
export shell	# allow each test script to know what shell is running it

# --- main ---
while read shell <&8; do
	shell=${shell%%[ $CCt]#*} 	# remove comments
	trim shell			# remove leading/trailing whitespace
	is_shell $shell || continue

	shell=$shell${posix_args:+ }$posix_args
	printf '%s> %s%s%s\n' "$tGreen" "$tBlue" $shell "$tReset"
	eval "${opt_t+time} $shell ${opt_c+-c} -- \$script \"\$@\"" 8<&-
	e=$?
	let e==0 && ec=$tGreen || ec=$tRed
	printf '%s%s[exit %s%d%s]%s\n' "$tReset" "$tBlue" "$ec" $e "$tBlue" "$tReset"
done 8<$shellsfile
