#! test/script/for/moderni/sh
#! use safe -wBUG_APPENDC
#! use var/arith
#! use sys/base/mktemp
#! use var/setlocal
#! use loop/with
#! use var/string
#! use var/mapr
# See the file LICENSE in the main modernish directory for the licence.

showusage() {
	echo "usage: modernish --test [ -eqsx ] [ -t FILE[:NUM[,NUM,...]][/...] ]"
	echo "	-e: run expensive tests that are disabled by default"
	echo "	-q: quiet operation (use 2x for quieter, 3x for quietest)"
	echo "	-s: silent operation"
	echo "	-t: run specific tests by name and/or number, e.g.: -t match:3,4/stack"
	echo "	-x: produce xtrace, keep fails (use 2x to keep xfails, 3x to keep all)"
} 1>&2

if ! test -n "${MSH_VERSION+s}"; then
	echo "Run me with: modernish --test" >&2
	showusage
	exit 1
fi

cd "$MSH_PREFIX" || die

# Make things awkward as an extra robustness test:
# - Run the test suite with no PATH; modernish *must* cope with this, even
#   on 'yash -o posix' which does $PATH lookups on all regular builtins.
PATH=/dev/null
# - Run with 'umask 777' (zero default file permissions). This is to check
#   that library functions set safe umasks whenever files are created. It
#   also checks for BUG_HDOCMASK compatibility with here-documents.
umask 777

# parse options
let "opt_e = opt_q = opt_s = opt_x = 0"
unset -v opt_t
while getopts 'eqst:x' opt; do
	case $opt in
	( \? )	exit -u 1 ;;
	( e )	inc opt_e ;;		# run expensive tests
	( q )	inc opt_q ;;		# quiet operation
	( s )	inc opt_s ;;		# silent operation
	( t )	opt_t=$OPTARG ;;	# run specific tests
	( x )	inc opt_x ;;		# produce xtrace
	esac
done
shift $(($OPTIND - 1))
case $# in
( [!0]* ) exit -u 1 ;;
esac

if let opt_s; then
	opt_q=999
	exec >/dev/null
fi

if let opt_x || isset -x; then
	# Set a useful PS4 for xtrace output.
	# The ${foo#{foo%/*/*}/} substitutions below are to trace just the last two
	# elements of path names, instead of the full paths which can be very long.
	if isset BASH_VERSION; then
		PS4='+ [${BASH_SOURCE+${BASH_SOURCE#${BASH_SOURCE%/*/*}/},}${FUNCNAME+$FUNCNAME,}${LINENO+$LINENO,}$?] '
	elif isset ZSH_VERSION; then
		PS4='+ [${funcfiletrace+${funcfiletrace#${funcfiletrace%/*/*}/},}${funcstack+${funcstack#${funcstack%/*/*}/},}${LINENO+$LINENO,}$?] '
	elif (eval '[[ -n ${.sh.version+s} ]]') 2>/dev/null; then  # ksh93
		PS4='+ [${.sh.file+${.sh.file#${.sh.file%/*/*}/},}${.sh.fun+${.sh.fun},}${LINENO+$LINENO,}$?] '
	else	# plain POSIX
		PS4='+ [${LINENO+$LINENO,}$?] '
	fi
fi
if let opt_x; then
	# Create temporary directory for trace output (one file per test).
	mktemp -ds /tmp/msh-xtrace.XXXXXXXXXX
	xtracedir=$REPLY
	xtracedir_q=$REPLY
	shellquote xtracedir_q
	if gt opt_x 2; then
		xtracemsg_q="Leaving all xtraces in $xtracedir_q"
		shellquote xtracemsg_q
		pushtrap "putln $xtracemsg_q >&3" INT PIPE TERM EXIT DIE
	else
		if gt opt_x 1; then
			xtracemsg_q="Leaving failed and xfailed tests' xtraces in $xtracedir_q"
		else
			xtracemsg_q="Leaving failed tests' xtraces in $xtracedir_q"
		fi
		shellquote xtracemsg_q
		pushtrap "PATH=\$DEFPATH command rmdir $xtracedir_q 2>/dev/null || \
			putln $xtracemsg_q >&3" INT PIPE TERM EXIT DIE
	fi
fi

if isset opt_t; then
	# Parse -t option argument.
	# Format: one or more slash-separated entries, consisting of a test set name (the basename of a
	# '*.t' script), optionally followed by a semicolon and a comma-separated list of test numbers.
	# TODO: if/when modernish implements associative arrays, use one instead of appending with separator
	allscripts=
	allnums=
	setlocal s n --split=/ -- $opt_t; do
		for s do
			setlocal --split=: -- $s; do
				if lt $# 1 || empty $1; then
					exit -u 1 "--test: -t: empty test set name"
				fi
				s=$1
				n=${2-}
			endlocal
			s=${s%.t}  # remove extension
			if not is reg $MSH_PREFIX/$testsdir/$s.t; then
				exit 1 "--test: -t: no test set by that name: $s"
			fi
			append --sep=: allscripts $testsdir/$s.t
			if not empty $n; then
				setlocal i ii --split=,$WHITESPACE -- $n; do
					for i do
						while startswith $i 0; do
							i=${i#0}
						done
						append --sep=, ii $i
					done
					append --sep=/ allnums $s:$ii
				endlocal
			fi
		done
	endlocal
else
	allscripts=$testsdir/*.t
	allnums=
fi

# do this at the end of option parsing so error messages are not suppressed with -qq and -s
exec 3>&2  # save stderr in 3 for msgs from traps
if let "opt_q > 1"; then
	exec 2>/dev/null
fi

# determine terminal capabilities
harden -p -e '==2 || >4' tput
tReset=
tRed=
tBold=
if is onterminal 1; then
	if tReset=$(tput sgr0); then	# tput uses terminfo codes
		tBold=$(tput bold)
		tRed=$tBold$(tput setaf 1)
	elif tReset=$(tput me); then	# tput uses termcap codes
		tBold=$(tput md)
		tRed=$tBold$(tput AF 1)
	fi 2>/dev/null
fi

# Harden utilities used below and in tests, searching them in the system default PATH.
harden -pP cat
harden -p fold
harden -p ln
harden -p mkdir -m u+rwx
harden -p paste
harden -p rm
harden -p sed
harden -p sort
if thisshellhas BUG_PFRPAD; then
	# use external 'printf' to circumvent right-hand blank padding bug in printf builtin
	harden -pX printf
else
	harden -p printf
fi

# Run all the bug/quirk/feature tests and cache their results.
thisshellhas --cache

if lt opt_q 2; then
	# intro
	putln "$tReset$tBold--- modernish $MSH_VERSION test suite ---$tReset"

	# Identify the version of this shell, if possible.
	case \
	${BASH_VERSION+ba}${KSH_VERSION+k}${NETBSD_SHELL+n}${POSH_VERSION+po}${SH_VERSION+k}${YASH_VERSION+ya}${ZSH_VERSION+z} \
	in
	( ya )	putln "* This shell identifies itself as yash version $YASH_VERSION" ;;
	( k )	isset -v KSH_VERSION || KSH_VERSION=$SH_VERSION
		case $KSH_VERSION in
		( '@(#)MIRBSD KSH '* )
			putln "* This shell identifies itself as mksh version ${KSH_VERSION#*KSH }." ;;
		( '@(#)LEGACY KSH '* )
			putln "* This shell identifies itself as lksh version ${KSH_VERSION#*KSH }." ;;
		( '@(#)PD KSH v'* )
			putln "* This shell identifies itself as pdksh version ${KSH_VERSION#*KSH v}."
			if endswith $KSH_VERSION 'v5.2.14 99/07/13.2'; then
				putln "  (Note: many different pdksh variants carry this version identifier.)"
			fi ;;
		( Version* )
			putln "* This shell identifies itself as AT&T ksh93 v${KSH_VERSION#V}." ;;
		( * )	putln "* WARNING: This shell has an unknown \$KSH_VERSION identifier: $KSH_VERSION." ;;
		esac ;;
	( z )	putln "* This shell identifies itself as zsh version $ZSH_VERSION." ;;
	( ba )	putln "* This shell identifies itself as bash version $BASH_VERSION." ;;
	( po )	putln "* This shell identifies itself as posh version $POSH_VERSION." ;;
	( n )	putln "* This shell identifies itself as NetBSD sh version $NETBSD_SHELL." ;;
	( * )	if (eval '[[ -n ${.sh.version+s} ]]') 2>/dev/null; then
			eval 'putln "* This shell identifies itself as AT&T ksh v${.sh.version#V}."'
		else
			putln "* This is a POSIX-compliant shell without a known version identifier variable."
		fi ;;
	esac
	if lt opt_q 1; then
		putln "  Modernish detected the following bugs, quirks and/or extra features on it:"
		thisshellhas --show | sort | paste -s -d ' ' - | fold -s -w 78 | sed 's/^/  /'
	fi
fi

# A couple of helper functions for regression tests that verify bug/quirk/feature detection.
# The exit status of these helper functions is to be passed down by the doTest* functions.
mustNotHave() {
	if not thisshellhas $1; then
		case $1 in
		( BUG_* | QRK_* | WRN_* )
			;;
		( * )	okmsg="no $1"
			skipmsg="no $1" ;;
		esac
	else
		failmsg="$1 wrongly detected"
		return 1
	fi
}
mustHave() {
	if thisshellhas $1; then
		case $1 in
		( BUG_* | WRN_* )
			xfailmsg=$1
			return 2 ;;
		esac
		okmsg=$1
	else
		failmsg="$1 not detected"
		return 1
	fi
}

# Helper function for tests that are only applicable in a UTF-8 locale.
# Usage: utf8Locale || return
utf8Locale() {
	case ${LC_ALL:-${LC_CTYPE:-${LANG:-}}} in
	( *[Uu][Tt][Ff]8* | *[Uu][Tt][Ff]-8* )
		;;
	( * )	skipmsg='non-UTF-8 locale'
		return 3 ;;
	esac
}

# Helper function to skip or reduce expensive tests.
# Use:	runExpensive || return
#	runExpensive || { reduce expense somehow; }
runExpensive() {
	if eq opt_e 0; then
		skipmsg='expensive'
		return 3
	fi
}

# Create a temporary directory for the tests to use.
# modernish mktemp: [s]ilent (no output); auto-[C]leanup; [d]irectory; store path in $REPLY
mktemp -sCCCd /tmp/msh-test.XXXXXX
testdir=$REPLY

# Run the tests.
let "oks = fails = xfails = skips = total = 0"
setlocal --split=: --glob -- $allscripts; do
	for testscript do
		testset=${testscript##*/}
		testset=${testset%.t}
		header="* ${tBold}$testsdir/$tRed$testset$tReset$tBold.t$tReset "
		unset -v v
		if eq opt_q 0; then
			putln $header
			unset -v header
		fi
		unset -v lastTest
		source $testscript || die "$testscript: failed to source"
		isset -v lastTest || lastTest=999
		# ... determine which tests to execute
		if contains "/$allnums/" "/$testset:"; then
			# only execute numbers given with -t
			nums=/$allnums
			nums=${nums##*/$testset:}
			nums=${nums%%/*}
		else
			nums=
			with num=1 to $lastTest; do
				if command -v doTest$num >/dev/null 2>&1; then
					append --sep=, nums $num
				fi
			done
		fi
		# ... run the numbered test functions
		setlocal --split=, -- $nums; do
			for num do
				inc total
				title='(untitled)'
				unset -v okmsg failmsg xfailmsg skipmsg
				if let opt_x; then
					case $num in
					( ? )	xtracefile=00$num ;;
					( ?? )	xtracefile=0$num ;;
					( * )	xtracefile=$num ;;
					esac
					xtracefile=$xtracedir/${testscript##*/}.$xtracefile.out
					umask 022
					command : >$xtracefile || die "tests/run.sh: cannot create $xtracefile"
					umask 777
					{
						set -x
						doTest$num
						result=$?
						set +x
					} 2>|$xtracefile
					gt $? 0 && die "tests/run.sh: cannot write to $xtracefile"
				else
					doTest$num
					result=$?
				fi
				case $result in
				( 0 )	resultmsg=ok${okmsg+\: $okmsg}
					let "opt_x > 0 && opt_x < 3" && { rm $xtracefile & }
					inc oks ;;
				( 1 )	resultmsg=${tRed}FAIL${tReset}${failmsg+\: $failmsg}
					inc fails ;;
				( 2 )	resultmsg=xfail${xfailmsg+\: $xfailmsg}
					let "opt_x > 0 && opt_x < 2" && { rm $xtracefile & }
					inc xfails ;;
				( 3 )	resultmsg=skipped${skipmsg+\: $skipmsg}
					let "opt_x > 0 && opt_x < 3" && { rm $xtracefile & }
					inc skips ;;
				( 127 )	die "$testset test $num: test not found" ;;
				( * )	die "$testset test $num: unexpected status $result" ;;
				esac
				if let "opt_q==0 || result==1 || (opt_q==1 && result==2)"; then
					if isset -v header; then
						putln $header
						unset -v header
					fi
					printf '  %03d: %-40s - %s\n' $num $title $resultmsg
				fi
			done
			# only unset the functions after running all, as -t may run them repeatedly
			for num do
				unset -f doTest$num
			done
		endlocal
	done
endlocal

# report
if lt opt_q 3; then
	eq total 1 && v1=test || v1=tests
	eq skips 1 && v2=was || v2=were
	putln "Out of $total $v1:" "- $oks succeeded" "- $skips $v2 skipped" "- $xfails failed expectedly"
fi
if gt fails 0; then
	putln "$tRed- $fails failed unexpectedly$tReset"
	if lt opt_q 2 && gt opt_x 0; then
		putln "  Please report bug with xtrace at ${tBold}https://github.com/modernish/modernish$tReset"
	fi
elif lt opt_q 3; then
	putln "- 0 failed unexpectedly"
fi
wait

# return/exit unsuccessfully if there were failures
eq fails 0
