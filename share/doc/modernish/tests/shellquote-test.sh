#! /usr/bin/env modernish
#! use safe -k
#! use var/loop

# Test and demonstration program for shellquote().
# See README.md under "Low-level shell utilities" -> "shellquote" for more info.
#
# This program includes an -N option for trying the current shell's builtin
# quoting algorithm. Its output is not always portable, and it's generally
# *much* worse at minimising exponential growth when quoting multiple times.

PATH=$DEFPATH   # use standard utilities, esp. 'tput'

showusage() {
	putln "usage: ${ME##*/} [ -n DEPTHLEVEL ] [ -f ] [ -P | -N ] [ STRING ]"
}

# Parse options.
force='' method='' level=6
while getopts n:fPN opt; do
	case $opt in
	( n )	level=$OPTARG ;;	# Number of times to quote
	( f )	force='-f' ;;		# Force quoting shell-safe strings
	( P )	method='-P' ;;		# Portable POSIX quoting (no $CC*)
	( N )	method=native ;;	# Use shell's native algorithm
	( * )	exit -u 1 ;;		# 'exit -u' calls showusage()
	esac
done
shift $((OPTIND-1))
str isint $level || exit -u 1 "bad number: $level"

# Set the string to quote.
if let "$#"; then
	# "$*" separates all arguments with the first character of IFS.
	# But in the safe mode, IFS is emptied to disable global field
	# splitting, so there would be no separator.
	push IFS; IFS=' '; quotestring="$*"; pop IFS
else
	quotestring='Let`s \see hôw modernish shellquote()
		"handles" '\''quoting'\'' $of '${CCv}'`weird` multi#line \$strings\\.
		(To try another string, specify one on the command line.)\'
fi
quotestring_orig=$quotestring

# Quoted strings can get large, so make them easier to tell apart.
if is onterminal 1; then
	emphasis=$(tput md; tput setaf 1 2>/dev/null || tput rev) # bold & either red or reverse
	reset=$(tput sgr0)
else
	emphasis='' reset=''
fi

# Quote the specified number of levels with specified options.
LOOP for i=1 to level; DO
	case $method in
	( native )
		# Set a dummy alias in a subshell and ask the shell to print
		# it, quoting the value with its internal algorithm.
		quotestring=$(alias Q=$quotestring; alias Q)
		quotestring=${quotestring#*Q=} ;;
	( * )
		# Modernish shellquoting.
		#    (Due to the shell's empty removal mechanism, $force
		#    and $method below are skipped entirely if empty.)
		shellquote $force $method quotestring ;;
	esac
	putln "${emphasis}q$i: [${#quotestring}]$reset $quotestring" ""
DONE

# Roll back the quoting and verify the results.
LOOP for i=level-1 to 0; DO
	eval quotestring=$quotestring || exit
	putln "${emphasis}u$i: [${#quotestring}]$reset $quotestring" ""
DONE
str eq $quotestring $quotestring_orig && putln ok
