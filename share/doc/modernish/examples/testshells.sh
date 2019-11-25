#! /usr/bin/env modernish
#! use safe -k
#! use sys/base/mktemp	# for modernish mktemp (note: -C = auto-cleanup!)
#! use sys/cmd/harden
#! use var/local
#! use var/loop
#! use var/unexport
#! use var/string	# for 'trim', 'replacein'
#! use var/shellquote

# testshells: test any command or script on multiple POSIX shells.

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
		use sys/term/readkey
		harden -p -e '> 1' grep
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
			which -aq sh ash dash gwsh zsh5 zsh yash bash ksh ksh93 lksh mksh oksh pdksh
			if is -L reg /etc/shells && can read /etc/shells; then
				grep -E '/([bdy]?a|gw|pdk|[mlo]?k|z)?sh[0-9._-]*$' /etc/shells
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

# Create temporary directory for 'sh' symlinks.
mktemp -dsCC '/tmp/POSIXMODE_'		# 2x -C = clean up temp dir even on SIGINT (Ctrl-C)
posix_sh_dir=$REPLY

if isset opt_P; then
	# Make shells and utilities behave POSIXly.
	export POSIXLY_CORRECT=y
else
	# Keep POSIX mode set for current shell environment only.
	unexport POSIXLY_CORRECT
fi

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
	if not isset opt_P || str end $1 /sh; then
		return
	fi

	# Figure out how to set POSIX mode for this shell, storing result back in $shell.
	for args in \
		'-o posix' \
		'--emulate sh -o POSIX_ARGZERO'
	do
		hi=$(IFS=' '; exec "$@" $args -c 'echo hi' 2>/dev/null)
		if str eq $hi 'hi'; then
			shell="$shell $args"
			return
		fi
	done

	# We can't set POSIX mode with a command line argument, so use a symlink
	# called 'sh' in hopes the shell will notice it is being launched as 'sh'.
	# As of 2019, the only shell known to need this is zsh <= 5.4.2, but it doesn't hurt others.
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
	check_shell || continue

	# Print header.
	printf '%s> %s%s%s\n' "$tGreen" "$tBlue" $shell "$tReset"

	# Avoid script being processed as option.
	if str begin $script '-'; then
		isset opt_c && script=" $script" || script=./$script
	fi

	# Run script with current shell.
	eval "${opt_t+time} $shell ${opt_c+-c}" '"$script" "$@"' 8<&-

	# Report exit status.
	e=$?
	let e==0 && ec=$tGreen || ec=$tRed
	printf '%s%s[exit %s%d%s]%s\n' "$tReset" "$tBlue" "$ec" $e "$tBlue" "$tReset"
done 8<$shellsfile
