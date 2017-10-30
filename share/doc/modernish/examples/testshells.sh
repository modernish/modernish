#! /usr/bin/env modernish
#! use safe -w BUG_APPENDC
#! use sys/base/which
#! use sys/base/rev
#! use sys/term/readkey
#! use var/setlocal
#! use var/string
harden -p -e '> 1' grep
harden -p -e '== 2 || > 4' tput
harden -p printf
harden -p sort

unexport POSIXLY_CORRECT

# testshells: run a script on all known Bourne-ish shells.

# parse options
showusage() {
	putln "Usage: ${ME##*/} [ -t ] SCRIPT" \
		"	-t: time script execution"
}
unset -v opt_t
while getopts ':t' opt; do
	case $opt in
	( \? )	exit -u 1 "Invalid option: -$OPTARG" ;;
	( t )	opt_t='' ;;
	esac
done
shift $(($OPTIND - 1))

let $# || exit -u 2 "Specify one script to test, with optional arguments."
is -L reg $1 || exit 2 "Not found: $1"
can read $1 || exit 2 "No read permission: $1"
script=$1
shift

if isset opt_t && not thisshellhas time; then
	# harden external 'time' command against command not executable (126) or not found (127)
	harden -e '==126 || ==127' time
fi

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

# determine terminal capabilities (none if stdout (FD 1) is not on a terminal)
if is onterminal 1; then
	if tReset=$(tput sgr0 2>/dev/null); then
		# tput uses terminfo codes (most un*x systems)
		isset COLUMNS || COLUMNS=$(tput cols) || COLUMNS=80
		tBlue=$(tput setaf 4)
		tGreen=$(tput setaf 2)
		tRed=$(tput setaf 1)
		tEOL=$CCr$(tput cuf $((COLUMNS-5)))
	elif tReset=$(tput me 2>/dev/null); then
		# tput uses termcap codes (FreeBSD)
		isset COLUMNS || COLUMNS=$(tput co) || COLUMNS=80
		tBlue=$(tput AF 4)
		tGreen=$(tput AF 2)
		tRed=$(tput AF 1)
		tEOL=$CCr$(tput RI $((COLUMNS-5)))
	else
		# no known terminal capabilities
		isset COLUMNS || COLUMNS=80
		tReset=
		tBlue=
		tGreen=
		tRed=
		tEOL=$CCn$(printf "%$((COLUMNS-5))c" ' ')
	fi
else
	# stdout is not on a terminal; assume standard 80 column line width
	COLUMNS=80
	tReset=
	tBlue=
	tGreen=
	tRed=
	tEOL=$CCn$(printf "%$((COLUMNS-5))c" ' ')
fi #2>/dev/null	# redirecting stderr to /dev/null here prevents 'tput cols' above from
		# getting the correct number of columns on all shells, except zsh (!)

export COLUMNS

# find shells
shellsfile=~/.config/modernish/shellsrc
if not is -L reg $shellsfile; then
	harden -ptc mkdir -p -m700 ${shellsfile%/*}
	put "First run. Gathering shells into $shellsfile... "
	putln "# List of shells for testshells.sh. Arguments and shell grammar are supported." >|$shellsfile
	{
		which -q -a sh ash bash dash yash zsh zsh5 ksh ksh93 pdksh mksh lksh oksh
		# supplement 'which' results with any additional shells from /etc/shells
		if can read /etc/shells; then
			grep -E '^/[a-z/][a-z0-9/]+/[a-z]*sh[0-9]*$' /etc/shells |
				grep -vE '(csh|/esh|/psh|/posh|/fish|/r[a-z])'
		fi
	} | rev | sort -u | rev >>$shellsfile
	putln "Done." "Edit that file to your liking, or delete it to search again."
	if ask_q "Edit it now?"; then
		{ setlocal --dosplit	# $VISUAL or $EDITOR may contain arguments; must split
			${VISUAL:-${EDITOR:-vi}} "$shellsfile"
		endlocal } || exit 1 "Drat. Your editor failed."
	fi
	putln "Commencing regular operation."
fi

export shell	# allow each test script to know what shell is running it
while read shell <&8; do
	{ setlocal	# local positional parameters
		eval "set -- $shell"
		can exec ${1-}
	endlocal } || continue

	printf '%s%24s: %s' "$tBlue" $shell "$tReset"
	eval "${opt_t+time} $shell \$script \"\$@\"" 8<&-
	e=$?
	if let e==0; then
		printf '%s%s[%3d]%s\n' "$tEOL" "$tGreen" $e "$tReset"
	else
		printf '%s%s[%3d]%s\n' "$tEOL" "$tRed" $e "$tReset"
	fi
done 8<$shellsfile
