#! test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# Shell arithmetic-related tests.
# Note: on shells without the 'let' builtin, modernish adds its own.

doTest1() {
	title='shell arithmetic supports octal'
	case $((014+032)) in
	( 38 )	return 0 ;;
	( 46 )	if thisshellhas BUG_NOOCTAL; then
			xfailmsg=BUG_NOOCTAL
			return 2
		else
			failmsg='BUG_NOOCTAL not detected'
			return 1
		fi ;;
	esac
	return 1
}

doTest2() {
	title='"let" supports octal'
	# on ksh93, this requires a special option (set -o letoctal); verify that it is set
	if let 014+032==38; then
		return 0
	elif thisshellhas BUG_NOOCTAL && let 014+032==46; then
		xfailmsg='BUG_NOOCTAL'
		return 2
	else
		return 1
	fi
}

doTest3() {
	title='"let" handles negative number as 1st arg'
	# check that it is not interpreted as an option
	let "-1" 2>/dev/null || return 1
}

doTest4() {
	title='check for arithmetic type restriction'
	xfailmsg=BUG_ARITHTYPE
	setlocal foo; do
		: $((foo = 0))	# does this assign an arithmetic type restriction?
		foo=4+5		# let's see...
		case $foo in
		( 4+5 )	return 0 ;;
		( 9 )	if thisshellhas BUG_ARITHTYPE; then
				xfailmsg=BUG_ARITHTYPE
				return 2
			else
				failmsg='BUG_ARITHTYPE not detected'
				return 1
			fi ;;
		esac
		failmsg='unknown bug'
		return 1
	endlocal
}

doTest5() {
	title='handling 64 bit integers'
	# regression test for QRK_32BIT detection.
	# First test if the shell exits on 64-bit numbers:
	if ! ( : $((9000000000)) ) 2>/dev/null; then
		if thisshellhas QRK_32BIT; then
			okmsg=QRK_32BIT
			return 0
		else
			failmsg='QRK_32BIT not detected'
			return 1
		fi
	fi
	{ foo=$((9000000000)); } 2>/dev/null
	case $foo in
	( 9000000000 )
		return 0 ;;
	# number wrapped around, 2147483647: number capped at maximum, or number truncated after 9 digits
	( 410065408 | 2147483647 | 900000000 )
		if thisshellhas QRK_32BIT; then
			okmsg=QRK_32BIT
			return 0
		else
			failmsg='QRK_32BIT not detected'
			return 1
		fi ;;
	esac
	failmsg='unknown bug'
	return 1
}

doTest6() {
	title='handling whitespace in arith expressions'
	# regression test for QRK_ARITHWHSP detection
	case $(	v="$CCn$CCt 1"		# newline, tab, space, 1
		{ : $((v)); } 2>/dev/null || exit
		put a1
		v="1$CCn$CCt "		# 1, newline, tab, space
		{ : $((v)); } 2>/dev/null || exit
		put a2
	) in
	( '' )	failmsg='unknown quirk'	# leading whitespace is not trimmed
		return 1 ;;
	(a1)	if thisshellhas QRK_ARITHWHSP; then
			okmsg=QRK_ARITHWHSP
			return 0
		else
			failmsg='QRK_ARITHWHSP not detected'
			return 1
		fi ;;
	(a1a2)	if thisshellhas QRK_ARITHWHSP; then
			failmsg='QRK_ARITHWHSP wrongly detected'
			return 1
		else
			return 0
		fi ;;
	esac
	return 1
}

lastTest=6
