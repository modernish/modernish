#! test/script/for/moderni/sh
#! use safe -k
#! use sys
#! use var

# Main execution script for the modernish regression test suite.
# See README.md or type 'modernish --test -h' for more information.
#
# --- begin license ---
# Copyright (c) 2019 Martijn Dekker <martijn@inlv.org>, Groningen, Netherlands
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# --- end license ---

showusage() {
	echo "usage: modernish --test [ -ehqsx ] [ -t FILE[:NUM[,NUM,...]][/...] ] [ -F PATH ]"
	echo "	-e: disable or reduce expensive regression tests"
	echo "	-h: show this help"
	echo "	-q: quiet operation (use 2x for quieter, 3x for quietest)"
	echo "	-s: silent operation"
	echo "	-t: run specific tests by name and/or number, e.g.: -t match:3,4/stack"
	echo "	-x: produce xtrace, keep fails (use 2x to keep xfails, 3x to keep all)"
	echo "	-E: don't run tests, output commands to edit them instead (use with -t)"
	echo "	-F: specify 'find' utility to use for testing 'LOOP find'"
}

if ! test -n "${MSH_VERSION+s}"; then
	echo "Run me with: modernish --test" >&2
	showusage
	exit 1
fi

chdir $MSH_PREFIX/$testsdir

# parse options
let "opt_e = opt_q = opt_s = opt_x = opt_E = 0"
unset -v opt_t opt_F
while getopts 'ehqst:xEF:' opt; do
	case $opt in
	( \? )	exit -u 1 ;;
	( e )	inc opt_e ;;		# disable/reduce expensive tests
	( h )	exit -u 0 ;;
	( q )	inc opt_q ;;		# quiet operation
	( s )	inc opt_s ;;		# silent operation
	( t )	opt_t=$OPTARG ;;	# run specific tests
	( x )	inc opt_x ;;		# produce xtrace
	( E )	inc opt_E ;;		# output commands to edit tests
	( F )	opt_F=$OPTARG ;;
	( * )	thisshellhas BUG_GETOPTSMA && str eq $opt ':' && exit -u 1
		exit 3 'internal error' ;;
	esac
done
shift $(($OPTIND - 1))
case $# in
( [!0]* ) exit -u 1 ;;
esac
if let opt_E; then
	thisshellhas BUG_LNNOALIAS && exit 2 '-E requires a shell without BUG_LNNOALIAS'
	thisshellhas BUG_LNNONEG && exit 2 '-E requires a shell without BUG_LNNONEG'
	thisshellhas LINENO || exit 2 '-E requires a shell with LINENO'
	let "opt_q = 3" "opt_e = opt_s = opt_x = 0"
	editor_cmdline=${VISUAL:-${EDITOR:-vi}}
fi

# Before we change PATH, explicitly init var/loop/find so it has a chance to
# find a standards-compliant 'find' utility in a nonstandard path if necessary.
use var/loop/find ${opt_F+$opt_F}

# Make things awkward as an extra robustness test:
# - Run the test suite with no PATH; modernish *must* cope with this, even
#   on 'yash -o posix' which does $PATH lookups on all regular builtins.
PATH=/dev/null
# - Run with 'umask 777' (zero default file permissions). This is to check
#   that library functions set safe umasks whenever files are created. It
#   also checks for BUG_HDOCMASK compatibility with here-documents.
umask 777

if let opt_s; then
	opt_q=999
	exec >/dev/null
fi

if let opt_x; then
	# Create temporary directory for trace output (one file per test).
	mktemp -ds /tmp/msh-xtrace.XXXXXXXXXX
	xtracedir=$REPLY
	shellquote xtracedir_q=$REPLY
	if gt opt_x 2; then
		shellquote xtracemsg_q="Leaving all xtraces in $xtracedir_q"
		pushtrap "putln $xtracemsg_q >&4" INT PIPE TERM EXIT DIE
	else
		if gt opt_x 1; then
			shellquote xtracemsg_q="Leaving failed and xfailed tests' xtraces in $xtracedir_q"
		else
			shellquote xtracemsg_q="Leaving failed tests' xtraces in $xtracedir_q"
		fi
		pushtrap "PATH=\$DEFPATH command rmdir $xtracedir_q 2>/dev/null || \
			putln $xtracemsg_q >&4" INT PIPE TERM EXIT DIE
	fi
fi

# Parse -t option argument.
# Format: one or more slash-separated entries, consisting of a test set name pattern (matching the basename of
# one or more '*.t' scripts), optionally followed by a semicolon and a comma-separated list of test numbers.
if not isset opt_t; then
	opt_t='*'
fi
allsets=
allnums=
LOOP for --split=/ testspec in $opt_t; DO
	LOCAL --split=: -- $testspec; BEGIN
		if lt $# 1 || str empty $1; then
			exit -u 1 "--test: -t: empty test set name"
		fi
		testsetpat=$1	# test set name pattern
		testnums=${2-}	# list of test numbers
	END
	# autocomplete an incomplete test set name
	LOCAL --fglob -- *.t; BEGIN
		str -M eq "$@" $testsetpat.t || str -M begin "$@" $testsetpat
	END
	if eq $? 1; then
		# no match: try it as a glob pattern
		if not str end $testsetpat '.t'; then
			testsetpat=$testsetpat.t
		fi
		LOCAL IFS='' --glob -- $testsetpat; BEGIN
			lt $# 1 && exit 1 "--test: -t: no such test set: ${testsetpat%.t}"
			IFS=$CCn
			testsets="$*"	# $CCn-separated glob results
		END
	else
		testsets=$REPLY		# results of 'str -M begin' (also $CCn-separated)
	fi
	LOOP for --split=$CCn testset in $testsets; DO
		testset=${testset%.t}
		append --sep=: allsets $testset
		if not str empty $testnums; then
			validatednums=
			LOOP for --split=,$WHITESPACE testnum in $testnums; DO
				str match $testnum *[!0123456789]* && exit -u 1 "--test: -t: invalid test number: $testnum"
				while str begin $testnum 0; do
					testnum=${testnum#0}
				done
				if not str in ",$validatednums," ",$testnum,"; then
					append --sep=, validatednums $testnum
				fi
			DONE
			append --sep=/ allnums $testset:$validatednums
		fi
	DONE
DONE

# do this at the end of option parsing so error messages are not suppressed with -qq and -s
exec 4>&2  # save stderr in 4 for msgs from traps
if let "opt_q > 1 && opt_E == 0"; then
	exec 2>/dev/null
fi

# determine terminal capabilities
tReset=
tRed=
tBold=
if is onterminal stdout && extern -pv tput >/dev/null; then
	harden -p -e '>4' PATH=$DEFPATH tput
	if tReset=$(tput sgr0); then
		tBold=$(tput bold)
		tRed=$tBold$(tput setaf 1)
	fi 2>/dev/null
fi

# Harden utilities used below and in tests, searching them in the system default PATH.
harden -pP cat
harden -p find
harden -p ln
harden -p mkdir -m 700	# u+rwx,go-rwx
harden -p pr
harden -p rm
harden -p sed
harden -p sort
harden -p wc
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
	putln "$tReset$tBold--- modernish $MSH_VERSION regression test suite ---$tReset"

	# Identify the version of this shell, if possible.
	. $MSH_AUX/id.sh
fi

# A couple of helper functions for regression tests that verify bug/quirk/feature detection.
# The exit status of these helper functions is to be passed down by the doTest* functions.
mustNotHave() {
	if not thisshellhas $1; then
		case $1 in
		( BUG_* | QRK_* | WRN_* )
			;;
		( * )	okmsg="no $1${okmsg:+ ($okmsg)}"
			skipmsg="no $1${skipmsg:+ ($skipmsg)}" ;;
		esac
	else
		failmsg="$1 wrongly detected${failmsg:+ ($failmsg)}"
		return 1
	fi
}
mustHave() {
	if thisshellhas $1; then
		case $1 in
		( BUG_* )
			xfailmsg="$1${xfailmsg:+ ($xfailmsg)}"
			return 2 ;;
		( WRN_* )
			warnmsg="$1${warnmsg:+ ($warnmsg)}"
			return 4 ;;
		esac
		okmsg=$1
	else
		failmsg="$1 not detected${failmsg:+ ($failmsg)}"
		return 1
	fi
}

# Helper function for tests that are only applicable in a UTF-8 locale.
# Usage: utf8Locale || return
utf8Locale() {
	case ${LC_ALL:-${LC_CTYPE:-${LANG:-}}} in
	( *[Uu][Tt][Ff]8* | *[Uu][Tt][Ff]-8* )
		;;
	( * )	skipmsg="non-UTF-8 locale${skipmsg:+ ($skipmsg)}"
		return 3 ;;
	esac
}

# Helper function to skip or reduce expensive tests.
# Use:	runExpensive || return
#	runExpensive || { reduce expense somehow; }
runExpensive() {
	if gt opt_e 0; then
		skipmsg="expensive${skipmsg:+ ($skipmsg)}"
		return 3
	fi
}

# Create a temporary directory for the tests to use.
# modernish mktemp: [s]ilent (no output); auto-[C]leanup; [d]irectory; store path in $REPLY
mktemp -sCCCd /tmp/msh-test.XXXXXX
tempdir=$REPLY

# Tests in *.t are delimited by these aliases.
let opt_E && alias TEST='{ _TESTLINE=$LINENO; testFn() {' || alias TEST='{ testFn() {'
alias ENDT='}; doTest; }'

# Function to run one test, called upon expanding the ENDT alias.
doTest() {
	inc num
	if isset nums; then
		not str in $nums ",$num," && return
		replacein -a nums "$num," ''
	fi
	inc total
	title='(untitled)'
	unset -v okmsg failmsg xfailmsg skipmsg warnmsg
	if let opt_x; then
		case $num in
		( ? )	xtracefile=00$num ;;
		( ?? )	xtracefile=0$num ;;
		( * )	xtracefile=$num ;;
		esac
		xtracefile=$xtracedir/${testscript##*/}.$xtracefile.out
		umask 022
		command : >$xtracefile || die "tst/run.sh: cannot create $xtracefile"
		umask 777
		{
			set -x
			testFn
			result=$?
			set +x
		} 2>|$xtracefile
		gt $? 0 && die "tst/run.sh: cannot write to $xtracefile"
	elif let opt_E; then
		editor_cmdline="${editor_cmdline} +${_TESTLINE} $testsdir/$testscript"
		result=3
	else
		testFn
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
	( 4 )	resultmsg=warning${warnmsg+\: $warnmsg}
		let "opt_x > 0 && opt_x < 2" && { rm $xtracefile & }
		inc warns ;;
	( * )	die "$testset test $num: unexpected status $result" ;;
	esac
	if let "opt_q==0 || result==1 || (opt_q==1 && result==2) || (opt_q==1 && result==4)"; then
		if isset -v header; then
			putln $header
			unset -v header
		fi
		printf '  %03d: %-40s - %s\n' $num $title $resultmsg
	fi
}

# Run the tests.
let "oks = fails = xfails = skips = warns = total = 0"
LOOP for --split=: testset in $allsets; DO
	testscript=$testset.t
	header="* ${tBold}$testsdir/$tRed$testset$tReset$tBold.t$tReset "
	unset -v v
	# ... determine which tests to execute
	if str in "/$allnums/" "/$testset:"; then
		# only execute numbers given with -t
		nums=/$allnums
		nums=${nums##*/$testset:}
		nums=",${nums%%/*},"
	else
		unset -v nums
	fi
	# ... run the test script, automatically numbering the test functions
	num=0
	source $testscript	# don't add '&& ...' or '|| ...' here; this kills tests involving ERR/ZERR traps
	if not so; then
		exit 128 "$testscript: failed to source"
	fi
	if isset nums && not str eq $nums ','; then
		trim nums ','
		exit 128 "$testscript: not found: $nums"
	fi
DONE

# report
if let opt_E; then
	putln $editor_cmdline
elif lt opt_q 3; then
	eq total 1 && v1=test || v1=tests
	eq skips 1 && v2=was || v2=were
	putln "Out of $total $v1:" \
		"- $oks succeeded" \
		"- $skips $v2 skipped" \
		"- $warns produced warnings" \
		"- $xfails failed expectedly"
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
