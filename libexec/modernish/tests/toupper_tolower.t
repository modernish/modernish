#! test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

doTest1() {
	title='tolower on variable (ASCII)'
	v=ABCDEFGHIJKLMNOPQRSTUVWXYZ
	tolower v
	identic $v abcdefghijklmnopqrstuvwxyz
}

doTest2() {
	title='toupper on variable (ASCII)'
	v=abcdefghijklmnopqrstuvwxyz
	toupper v
	identic $v ABCDEFGHIJKLMNOPQRSTUVWXYZ
}

doTest3() {
	title='tolower in pipe (ASCII)'
	v=$(put ABCDEFGHIJKLMNOPQRSTUVWXYZ | tolower)
	identic $v abcdefghijklmnopqrstuvwxyz
}

doTest4() {
	title='toupper in pipe (ASCII)'
	v=$(put abcdefghijklmnopqrstuvwxyz | toupper)
	identic $v ABCDEFGHIJKLMNOPQRSTUVWXYZ
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
	v='ABCDÉFĲN_ΑΒΓΔΕΖ_АБВГДЕ_ԱԲԳԴԵԶ'
	tolower v
	if identic $v 'abcdÉfĲn_ΑΒΓΔΕΖ_АБВГДЕ_ԱԲԳԴԵԶ' && thisshellhas BUG_CNONASCII; then
		xfailmsg=BUG_CNONASCII
		return 2
	fi
	identic $v 'abcdéfĳn_αβγδεζ_абвгде_աբգդեզ'
}

doTest6() {
	title='toupper on variable (UTF-8)'
	utf8Locale || return
	v='abcdéfĳn_αβγδεζ_абвгде_աբգդեզ'
	toupper v
	if identic $v 'ABCDéFĳN_αβγδεζ_абвгде_աբգդեզ' && thisshellhas BUG_CNONASCII; then
		xfailmsg=BUG_CNONASCII
		return 2
	fi
	identic $v 'ABCDÉFĲN_ΑΒΓΔΕΖ_АБВГДЕ_ԱԲԳԴԵԶ'
}

doTest7() {
	title='tolower in pipe (UTF-8)'
	utf8Locale || return
	v=$(put 'ABCDÉFĲN_ΑΒΓΔΕΖ_АБВГДЕ_ԱԲԳԴԵԶ' | tolower)
	if identic $v 'abcdÉfĲn_ΑΒΓΔΕΖ_АБВГДЕ_ԱԲԳԴԵԶ' && thisshellhas BUG_CNONASCII; then
		xfailmsg=BUG_CNONASCII
		return 2
	fi
	identic $v 'abcdéfĳn_αβγδεζ_абвгде_աբգդեզ'
}

doTest8() {
	title='toupper in pipe (UTF-8)'
	utf8Locale || return
	v=$(put 'abcdéfĳn_αβγδεζ_абвгде_աբգդեզ' | toupper)
	if identic $v 'ABCDéFĳN_αβγδεζ_абвгде_աբգդեզ' && thisshellhas BUG_CNONASCII; then
		xfailmsg=BUG_CNONASCII
		return 2
	fi
	identic $v 'ABCDÉFĲN_ΑΒΓΔΕΖ_АБВГДЕ_ԱԲԳԴԵԶ'
}

lastTest=8
