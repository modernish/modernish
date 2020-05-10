#! /usr/bin/env modernish
#! use safe -k
#! use sys/cmd/harden
#! use sys/cmd/procsubst
#! use sys/term/readkey
#! use var/arith

# ------------------------------------------
#  dice.sh: simulate rolling a pair of dice
#  with strong randomness from /dev/urandom
# ------------------------------------------
#
# Based on Korn Shell Dice. Used by permission.
# Refactored and ported to modernish by Martijn Dekker <martijn@inlv.org>.
# Original: gopher://sdf.org/0/users/jgw/Misc/dice.ksh
# See the file LICENSE in the main modernish directory for the licence.

# --- harden utilities used ---

harden -p -e '>4' tput

# Solaris 'sleep' enforces locale-specific fractions (like 'sleep .5' versus
# 'sleep 0,5'); make locale-independent by setting POSIX locale for numbers
harden -p -u LC_ALL LC_NUMERIC=POSIX sleep

# awk and od for randomDiceStream(): use -P to expect termination by SIGPIPE
harden -pP -e '>125' awk	# some awk exit 1 or 2 when killed by SIGPIPE
harden -pP od

# extra robustness: disallow non-hardened utilities
PATH=/dev/null

# --- init variables ---

if is onterminal stdout; then
	clear=$(tput clear) || die "tput failed"
	reset=$(tput sgr0)
	bold=$(tput bold)
	red=$(tput setaf 1)
else
	clear=$CCf reset= bold= red=
fi

if str ematch ${LC_ALL:-${LC_CTYPE:-${LANG:-}}} [Uu][Tt][Ff]-?8; then
	# In UTF-8 locale: use fancy characters
	diceHdr='   ⚀  ⚁  :  ⚂  ⚃  :  ⚄  ⚅'
	diceHoriz1='┏━━━━━━━┓'
	diceVertic='┃'
	diceHoriz2='┗━━━━━━━┛'
	o="•"
else
	diceHdr='   1  2  :  3  4  :  5  6'
	diceHoriz1='+-------+'
	diceVertic='|'
	diceHoriz2='+-------+'
	o="o"
fi

# --- define functions ---

showusage() {
	me=${ME##*/}
	putln	"  usage: $me NUM [ TIME ]" \
		"         $me -p [ NUM ]" \
		"         $me -h" \
		'      -h = prints usage info' \
		'      -p = pauses between rolls; continuous if NUM omitted' \
		'     NUM = number of rolls of dice desired' \
		'    TIME = seconds between rolls (2 default)'
}

printDie() {
	case $1 in
	1)	set --	"     " \
			"  $o  " \
			"     " ;;

	2)	set --	"    $o" \
			"     " \
			"$o    " ;;

	3)	set --	"    $o" \
			"  $o  " \
			"$o    " ;;

	4)	set --	"$o   $o" \
			"     " \
			"$o   $o" ;;

	5)	set --	"$o   $o" \
			"  $o  " \
			"$o   $o" ;;

	6)	set --	"$o   $o" \
			"$o   $o" \
			"$o   $o" ;;
	esac
	putln '' "$CCt$bold$diceHoriz1" \
		"$CCt$diceVertic$red $1 $reset$bold$diceVertic" \
		"$CCt$diceVertic$red $2 $reset$bold$diceVertic" \
		"$CCt$diceVertic$red $3 $reset$bold$diceVertic" \
		"$CCt$diceHoriz2$reset"
}

printDiceTerm() {
	let "total = $1 + $2"
	case $total in
	2)	term="Snake Eyes" ;;
	3)	term="Ace caught a Deuce" ;;
	5)	term="Fever Five" ;;
	7)	term="Big Red" ;;
	4 | 6 | 8 | 10)
		if eq $1 $2; then
			term="$total the Hard Way"
		else
			term="$total the Easy Way"
		fi ;;
	9)	term="Center Field Nine" ;;
	11)	term="Yo-Leven" ;;
	12)	term="Box Cars" ;;
	esac
	putln '' "$CCt=> $term !!" ''
}

# The following four functions are the most interesting bit. Not all shells
# have a built-in random number generator, so we read bytes from /dev/urandom
# (which is on nearly all Unixy OSs have these days) and process them into an
# infinite stream of random numbers 1-6 (one per line). The doNum and doPause
# functions, upon invocation, automatically connect that stream to file
# descriptor 3 using the portable process substitution construct provided by
# the var/cmd/procsubst module. Both of these functions call rollDice for each
# roll, which can then simply read random numbers 1-6 from file descriptor 3.

randomDiceStream() {
	od -v -An -tu1 < /dev/urandom \
	| awk '{ for (i = 1; i <= NF; i++) print $i % 6 + 1; }'
}

rollDice() {
	putln $clear \
		' Welcome to Modernish Dice!' \
		$diceHdr \
		'' \
		"  roll #$1:" \
		''
	read Die_1 <&3 && read Die_2 <&3 || die "failed to read dice"
	printDie $Die_1
	printDie $Die_2
	printDiceTerm $Die_1 $Die_2
}

doNum() {
	T=0
	until ge T+=1 $1; do
		rollDice $T
		str eq $2 0 || sleep $2
	done
	rollDice $T
} 3< $(% randomDiceStream)

doPause() {
	T=0
	REPLY=
	until str match $REPLY [qQ]; do
		inc T
		rollDice $T
		if gt $1 0 && ge T $1; then
			break
		fi
		putln '' 'press ANY KEY to continue ; Q to quit' ''
		readkey
	done
} 3< $(% randomDiceStream)

# --- main ---

# ... parse options
opt_p=0
while getopts 'ph' opt; do
	case $opt in
	p)	inc opt_p ;;
	h)	exit -u 0 ;;
	*)	exit -u 1 ;;
	esac
done
shift $((OPTIND - 1))

# ... validate and execute
gt $# "opt_p ? 1 : 2" && exit -u 1 "too many arguments"
let $# && { str isint $1 && gt $1 0 || exit -u 1 "invalid number of rolls: $1"; }
if let $#; then
	str isint $1 && gt $1 0 || exit -u 1 "invalid number of rolls: $1"
fi
if let opt_p; then
	doPause ${1:-'0'}
else
	let $# || exit -u 1 "number of rolls required"
	# We don't validate the second argument ($2) because it's passed to
	# "sleep" which may take different arguments depending on the
	# implementation (i.e. fractions). Make it default to 2, though.
	doNum $1 ${2:-'2'}
fi
