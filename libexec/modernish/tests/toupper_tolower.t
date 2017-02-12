#! test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

doTest1() {
	title='tolower on variable (ASCII)'
	v='MARTIJN DEKKER'
	tolower v
	identic $v 'martijn dekker'
}

doTest2() {
	title='toupper on variable (ASCII)'
	v='martijn dekker'
	toupper v
	identic $v 'MARTIJN DEKKER'
}

doTest3() {
	title='tolower in pipe (ASCII)'
	v=$(echo 'MARTIJN DEKKER' | tolower)
	identic $v 'martijn dekker'
}

doTest4() {
	title='toupper in pipe (ASCII)'
	v=$(echo 'martijn dekker' | toupper)
	identic $v 'MARTIJN DEKKER'
}

utf8Locale() {
	case ${LC_ALL:-${LC_CTYPE:-${LANG:-}}} in
	( *[Uu][Tt][Ff]8* | *[Uu][Tt][Ff]-8* )
		;;
	( * )	skipmsg='non-UTF-8 locale'
		return 3 ;;
	esac
}

doTest5() {
	title='tolower on variable (UTF-8)'
	utf8Locale || return
	v='MΑRTĲN ΔΕΚΚΕΡ'
	tolower v
	if identic $v 'mΑrtĲn ΔΕΚΚΕΡ' && thisshellhas BUG_CNONASCII; then
		xfailmsg=BUG_CNONASCII
		return 2
	fi
	identic $v 'mαrtĳn δεκκερ'
}

doTest6() {
	title='toupper on variable (UTF-8)'
	utf8Locale || return
	v='mαrtĳn δεκκερ'
	toupper v
	if identic $v 'MαRTĳN δεκκερ' && thisshellhas BUG_CNONASCII; then
		xfailmsg=BUG_CNONASCII
		return 2
	fi
	identic $v 'MΑRTĲN ΔΕΚΚΕΡ'
}

doTest7() {
	title='tolower in pipe (UTF-8)'
	utf8Locale || return
	v=$(echo 'MΑRTĲN ΔΕΚΚΕΡ' | tolower)
	if identic $v 'mΑrtĲn ΔΕΚΚΕΡ' && thisshellhas BUG_CNONASCII; then
		xfailmsg=BUG_CNONASCII
		return 2
	fi
	identic $v 'mαrtĳn δεκκερ'
}

doTest8() {
	title='toupper in pipe (UTF-8)'
	utf8Locale || return
	v=$(echo 'mαrtĳn δεκκερ' | toupper)
	if identic $v 'MαRTĳN δεκκερ' && thisshellhas BUG_CNONASCII; then
		xfailmsg=BUG_CNONASCII
		return 2
	fi
	identic $v 'MΑRTĲN ΔΕΚΚΕΡ'
}

lastTest=8
