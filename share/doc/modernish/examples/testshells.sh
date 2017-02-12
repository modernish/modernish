#! /usr/bin/env modernish
#! use safe -w BUG_UPP -w BUG_APPENDC
#! use sys/base/which
harden -p -e '> 1' grep
harden -p -e '> 1 && != 4' tput
harden -p printf

unexport POSIXLY_CORRECT

# testshells: run a script on all known Bourne-ish shells (grepping from /etc/shells).

let $# || exit 2 "Specify one script to test, with optional arguments."
is -L reg $1 || exit 2 "Not found: $1"
can read $1 || exit 2 "No read permission: $1"
script=$1
shift

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
which -as sh ash bash dash yash zsh zsh5 ksh ksh93 pdksh mksh lksh oksh
shells_to_test=$REPLY	# newline-separated list of shells to test
# supplement 'which' results with any additional shells from /etc/shells
if can read /etc/shells; then
	shells_to_test=${shells_to_test}${CCn}$(grep -E '^/[a-z/][a-z0-9/]+/[a-z]*sh[0-9]*$' /etc/shells |
		grep -vE '(csh|/esh|/psh|/posh|/fish|/r[a-z])')
fi

IFS=$CCn
shells_found=''
for shell in $shells_to_test; do
	# eliminate duplicates (symlinks, hard links)
	for alreadyfound in $shells_found; do
		if is samefile $shell $alreadyfound; then
			continue 2
		fi
	done
	can exec $shell || continue
	shells_found=$shells_found$shell$CCn

	printf '%s%24s: %s' "$tBlue" $shell "$tReset"
	if thisshellhas BUG_UPP; then
		$shell $script ${1+"$@"}
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
