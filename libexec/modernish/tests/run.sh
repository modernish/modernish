#! test/script/for/moderni/sh
#! use safe -wBUG_APPENDC
#! use var/arith
#! use sys/base/mktemp
#! use var/setlocal
#! use loop/with
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

usage() {
	echo "usage: modernish --test [ -q ] [ -s ]"
	echo "	-q: quiet operation (repeat for quieter)"
	echo "	-s: silent operation"
	echo "	-x: produce xtrace, keep fails (use twice to keep all)"
	exit 1
} 1>&2

if ! test -n "${MSH_VERSION+s}"; then
	echo "Run me with: modernish --test"
	usage
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
let "opt_q = opt_s = opt_x = 0"
while getopts 'qsx' opt; do
	case $opt in
	( \? )	usage ;;
	( q )	inc opt_q ;;		# quiet operation
	( s )	inc opt_s ;;		# silent operation
	( x )	inc opt_x ;;		# produce xtrace
	esac
done
shift $(($OPTIND - 1))
case $# in
( [!0]* ) usage ;;
esac

if let opt_s; then
	opt_q=999
	exec >/dev/null
fi

exec 3>&2  # save stderr in 3 for msgs from traps
if let "opt_q > 1"; then
	exec 2>/dev/null
fi

if let opt_x; then
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
	# Create temporary directory for trace output (one file per test).
	mktemp -ds /tmp/msh-xtrace.XXXXXXXXXX
	xtracedir=$REPLY
	xtracedir_q=$REPLY
	shellquote xtracedir_q
	if gt opt_x 1; then
		xtracemsg_q="Leaving all xtraces in $xtracedir_q"
		shellquote xtracemsg_q
		pushtrap "putln $xtracemsg_q >&3" INT PIPE TERM EXIT DIE
	else
		xtracemsg_q="Leaving failed tests' xtraces in $xtracedir_q"
		shellquote xtracemsg_q
		pushtrap "PATH=\$DEFPATH command rmdir $xtracedir_q 2>/dev/null || \
			putln $xtracemsg_q >&3" INT PIPE TERM EXIT DIE
	fi
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
	case ${YASH_VERSION+ya}${KSH_VERSION+k}${SH_VERSION+k}${ZSH_VERSION+z}${BASH_VERSION+ba}${POSH_VERSION+po} in
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

# Run the tests.
let "oks = fails = xfails = skips = total = 0"
set +f; for testscript in libexec/modernish/tests/*.t; do set -f
	header="$tBold* $testscript$tReset"
	if eq opt_q 0; then
		putln $header
		unset -v header
	fi
	unset -v lastTest
	source $testscript || die "$testscript: failed to source"
	isset -v lastTest || lastTest=999
	with num=1 to $lastTest; do
		if not command -v doTest$num >/dev/null 2>&1; then
			continue
		fi
		inc total
		title='(untitled)'
		unset -v okmsg failmsg xfailmsg skipmsg
		if let opt_x; then
			xtracefile=$xtracedir/${testscript##*/}.$(printf '%03d' $num).out
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
			eq opt_x 1 && rm $xtracefile
			inc oks ;;
		( 1 )	resultmsg=${tRed}FAIL${tReset}${failmsg+\: $failmsg}
			inc fails ;;
		( 2 )	resultmsg=xfail${xfailmsg+\: $xfailmsg}
			eq opt_x 1 && rm $xtracefile
			inc xfails ;;
		( 3 )	resultmsg=skipped${skipmsg+\: $skipmsg}
			eq opt_x 1 && rm $xtracefile
			inc skips ;;
		( * )	die "${testscript##*/}: doTest$num: unexpected status $result" ;;
		esac
		if let "opt_q==0 || result==1 || (opt_q==1 && result==2)"; then
			if isset -v header; then
				putln $header
				unset -v header
			fi
			printf '  %03d: %-40s - %s\n' $num $title $resultmsg
		fi
		unset -f doTest$num
	done
done

# report
if lt opt_q 3; then
	putln "Out of $total tests:" "- $oks succeeded"
	eq skips 1 && putln "- 1 was skipped" || putln "- $skips were skipped"
	putln "- $xfails failed expectedly"
fi
if gt fails 0; then
	putln "$tRed- $fails failed unexpectedly$tReset"
	if lt opt_q 2 && gt opt_x 0; then
		putln "  Please report bug with xtrace at ${tBold}https://github.com/modernish/modernish$tReset"
	fi
elif lt opt_q 3; then
	putln "- 0 failed unexpectedly"
fi

# return/exit unsuccessfully if there were failures
eq fails 0
