#! test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# Shell arithmetic-related tests.
# Note: on shells without the 'let' builtin, modernish adds its own.

doTest1() {
	title='shell arithmetic supports octal'
	xfailmsg='BUG_NOOCTAL'
	case $((014+032)) in
	( 38 )	return 0 ;;
	( 46 )	thisshellhas BUG_NOOCTAL && return 2 ;;
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
	title='"let" handles negative number as 1st argument"'
	# check that it is not interpreted as an option
	let "-1" 2>/dev/null || return 1
}

lastTest=3
