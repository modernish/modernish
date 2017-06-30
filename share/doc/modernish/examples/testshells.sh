#! /usr/bin/env modernish
#! use safe -w BUG_APPENDC
#! use sys/base/which
#! use sys/base/rev -w BUG_MULTIBYTE
#! use var/setlocal
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
	( t )	opt_t='' ;;		# non-interactive operation
	esac
done
shift $(($OPTIND - 1))

let $# || exit 2 "Specify one script to test, with optional arguments."
is -L reg $1 || exit 2 "Not found: $1"
can read $1 || exit 2 "No read permission: $1"
script=$1
shift

if isset opt_t && not thisshellhas time; then
	# harden external 'time' command against command not executable (126) or not found (127)
	harden -e '==126 || ==127' time
fi

# Simple function to ask a question of a user.
yesexpr=$(PATH=$DEFPATH exec locale yesexpr 2>/dev/null) || yesexpr=^[yY].*
match $yesexpr \"*\" && yesexpr=${yesexpr#\"} && yesexpr=${yesexpr%\"}	# one buggy old 'locale' command adds spurious quotes
ask_q() {
	REPLY=''
	while empty $REPLY; do
		put "$1 "
		read -r REPLY || exit 2 Aborting.
	done
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
shellsfile=~/.config/modernish/testshellsrc
if is -L reg $shellsfile; then
	shells_to_test=$(grep -v '#' $shellsfile)
else
	harden -ptc mkdir -p -m700 ${shellsfile%/*}
	put "First run. Gathering shells into $shellsfile... "
	which -as sh ash bash dash yash zsh zsh5 ksh ksh93 pdksh mksh lksh oksh
	shells_to_test=$REPLY	# newline-separated list of shells to test
	# supplement 'which' results with any additional shells from /etc/shells
	if can read /etc/shells; then
		shells_to_test=${shells_to_test}${CCn}$(grep -E '^/[a-z/][a-z0-9/]+/[a-z]*sh[0-9]*$' /etc/shells |
			grep -vE '(csh|/esh|/psh|/posh|/fish|/r[a-z])')
	fi
	putln "# List of shells for testshells.sh" >|$shellsfile
	putln $shells_to_test | rev | sort -u | rev >>$shellsfile
	putln "Done." "Edit that file to your liking, or delete it to search again."
	if ask_q "Edit it now?"; then
		{ setlocal --dosplit	# $VISUAL or $EDITOR may contain arguments; must split
			${VISUAL:-${EDITOR:-vi}} "$shellsfile" && shells_to_test=$(grep -v '#' "$shellsfile")
		endlocal } || exit 1 "Drat. Your editor failed."
	fi
	putln "Commencing regular operation."
fi

{ setlocal --split=$CCn
	for shell in $shells_to_test; do
		can exec $shell || continue

		printf '%s%24s: %s' "$tBlue" $shell "$tReset"
		if isset opt_t; then
			time $shell $script "$@"
		else
			$shell $script "$@"
		fi
		e=$?
		if let e==0; then
			printf '%s%s[%3d]%s\n' "$tEOL" "$tGreen" $e "$tReset"
		else
			printf '%s%s[%3d]%s\n' "$tEOL" "$tRed" $e "$tReset"
		fi
	done
endlocal }
