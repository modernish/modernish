#! test/script/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

usage() {
	echo "usage: modernish --test [ -q ] [ -s ]"
	echo "	-q: quiet operation (use twice for quieter)"
	echo "	-s: silent operation"
	exit 1
} 1>&2

if ! test -n "${MSH_VERSION+s}"; then
	echo "Run me with: modernish --test"
	usage
fi

cd "$MSH_PREFIX" || die

use safe -wBUG_APPENDC -wBUG_UPP
use var/arith
use sys/base/mktemp

harden -p printf
harden -p sort
harden -p paste
harden -p fold
harden -p sed

# parse options
let "opt_q = opt_s = 0"
while getopts 'qs' opt; do
	case $opt in
	( \? )	usage ;;
	( q )	inc opt_q ;;		# quiet operation
	( s )	inc opt_s ;;		# silent operation
	esac
done
shift $(($OPTIND - 1))
case $# in
( [!0]* ) usage ;;
esac

if let opt_s; then
	opt_q=2
	exec >/dev/null
fi

# determine terminal capabilities
harden -p -e '>1 && !=4' tput
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

if lt opt_q 2; then
	# intro
	putln "$tReset$tBold--- modernish $MSH_VERSION test suite ---$tReset"

	# Identify the version of this shell, if possible.
	case ${YASH_VERSION+ya}${KSH_VERSION+k}${SH_VERSION+k}${ZSH_VERSION+z}${BASH_VERSION+ba} in
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

# Run the tests.
let "num = oks = fails = xfails = skips = total = 0"
set +f; for testscript in libexec/modernish/tests/*.t; do set -f
	if lt opt_q 2; then
		putln "$tBold* $testscript$tReset"
	fi
	unset -v lastTest
	source $testscript || die "$testscript: failed to source"
	isset -v lastTest || lastTest=999
	while inc num; le num lastTest; do
		if not isset -f doTest$num; then
			continue
		fi
		inc total
		title='(untitled)'
		unset -v okmsg failmsg xfailmsg skipmsg
		doTest$num
		result=$?  # BUG_CASESTAT compat for 'die' message
		case $result in
		( 0 )	resultmsg=ok${okmsg+\: $okmsg}
			inc oks ;;
		( 1 )	resultmsg=${tRed}FAIL${tReset}${failmsg+\: $failmsg}
			inc fails ;;
		( 2 )	resultmsg=xfail${xfailmsg+\: $xfailmsg}
			inc xfails ;;
		( 3 )	resultmsg=skipped${skipmsg+\: $skipmsg}
			inc skips ;;
		( * )	die "${testscript##*/}: doTest$num: unexpected status $result" ;;
		esac
		if let "opt_q==0 || result==1 || (opt_q==1 && result==2)"; then
			printf '  %03d: %-40s - %s\n' $num $title $resultmsg
		fi
		if let "opt_q==0 && result==1"; then
			# show trace of failing test
			set -x
			{ doTest$num; } 2>&1
			{ set +x; } 2>/dev/null
		fi
		unset -f doTest$num
	done
	num=0
done

# report
putln "Out of $total tests:" "- $oks succeeded"
eq skips 1 && putln "- 1 was skipped" || putln "- $skips were skipped"
putln "- $xfails failed expectedly"
if gt fails 0; then
	putln "$tRed- $fails failed unexpectedly$tReset"
	lt opt_q 2 && putln "  Please report these at ${tBold}https://github.com/modernish/modernish$tReset"
else
	putln "- 0 failed unexpectedly"
fi

# return/exit unsuccessfully if there were failures
eq fails 0
