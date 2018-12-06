#! /usr/bin/env modernish
#! use safe -w BUG_APPENDC
#! use var/local
#! use var/unexport
harden -p -e '== 2 || > 4' tput
harden -p printf

unexport POSIXLY_CORRECT

# testshells: run a script on all known Bourne-ish shells.

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
	if not contains $script '/' && not is present $script; then
		# If file is not present in current dir, do a $PATH search
		LOCAL dir --split=':' -- $PATH; BEGIN
			for dir do
				if is -L reg $dir/$script && can read $dir/$script; then
					script=$dir/$script
					break
				fi
			done
		END
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
		use var/string
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
			ematch $REPLY $yesexpr
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

# make script set POSIX option if requested
if isset opt_P; then
	posixcode='
		export POSIXLY_CORRECT=y
		case ${ZSH_VERSION+s} in
		( s )	emulate -R sh; setopt POSIX_ARGZERO MULTIBYTE 2>/dev/null; PS4="+ " ;;
		( * )	(set -o posix) 2>/dev/null && set -o posix ;;
		esac
	'
	if isset opt_c; then
		script=$posixcode$CCn$script
	else
		use sys/base/mktemp

		mktemp -tsCC testshells_script  # note: auto-cleanup
		{ putln	$posixcode
		  harden -p -c cat $script
		} > $REPLY || die "can't write to $REPLY"
		script=$REPLY
	fi
fi

# parse shell grammar in $1, and check if the command is a shell
is_shell() {
	identic $(eval "${1-} -c 'echo hi'" 2>/dev/null) 'hi'
}

export shell	# allow each test script to know what shell is running it
while read shell <&8; do
	is_shell $shell || continue

	printf '%s> %s%s%s\n' "$tGreen" "$tBlue" $shell "$tReset"
	eval "${opt_t+time} $shell ${opt_c+-c} \$script \"\$@\"" 8<&-
	e=$?
	let e==0 && ec=$tGreen || ec=$tRed
	printf '%s%s[exit %s%d%s]%s\n' "$tReset" "$tBlue" "$ec" $e "$tBlue" "$tReset"
done 8<$shellsfile
