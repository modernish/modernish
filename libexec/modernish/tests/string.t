#! test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# Regression tests related to string and text processing.

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

doTest9() {
	title='backslash in nonexpanding here-document'
	# regression test for BUG_CSNHDBKSL detection
	command eval 'v=$(cat <<-\EOT'$CCn$CCt'abc \'$CCn$CCt'def \\'$CCn$CCt'ghi' \
		'\\\'$CCn$CCt'jkl \\\\'$CCn$CCt'end'$CCn$CCt'EOT'$CCn$CCt')'
	case $v in
	( 'abc \'$CCn'def \\'$CCn'ghi \\\'$CCn'jkl \\\\'$CCn'end' )
		return 0 ;;
	( 'abc '$CCt'def \\'$CCn'ghi \\'$CCt'jkl \\\\'$CCn'end' \
	| 'abc '$CCt'def \'$CCt'ghi \\'$CCt'jkl \\\'$CCt'end' )  # bash 2 and 3; bash 4.4
		if thisshellhas BUG_CSNHDBKSL; then
			xfailmsg=BUG_CSNHDBKSL
			return 2
		else
			failmsg='BUG_CSNHDBKSL not detected'
			return 1
		fi ;;
	( * )	failmsg='unknown bug'
		return 1 ;;
	esac
}

doTest10() {
	title='single-quoted pattern in param subst'
	# regression test for BUG_PSUBSQUOT detection
	v="${CCn}one${CCt}two'three/four'five"
	case "${v#${CCn}'one'${CCt}'two'\''three'}" in
	( "/four'five" )
		return 0 ;;
	( "$v" )
		if thisshellhas BUG_PSUBSQUOT; then
			xfailmsg=BUG_PSUBSQUOT
			return 2
		else
			failmsg='BUG_PSUBSQUOT not detected'
			return 1
		fi ;
	esac
	return 1
}

doTest11() {
	title='quoting within param subst in here-doc'
	# regression test for QRK_HDPARQUOT detection
	unset -v S U foo bar
	S=set
	# Of the test expansions below, only ${S#"se"}, ${S%"et"}, ${S##"se"} and ${S%%"et"}
	# have defined behaviour under POSIX (the double quotes must be removed).
	{ read -r foo; read -r bar; } <<-EOF
	${U-"1"}${U-'2'}${U:-"3"}${U:-'4'}${S+"5"}${S+'6'}${S:+"7"}${S:+'8'}
	${S#"se"}${S#'se'}${S%"et"}${S%'et'}${S##"se"}${S##'se'}${S%%"et"}${S%%'et'}
	EOF
	case $foo$bar in
	( \"1\"\'2\'\"3\"\'4\'\"5\"\'6\'\"7\"\'8\'ttssttss \
	| \"1\"\'2\'\"3\"\'4\'\"5\"\'6\'\"7\"\'8\'tsetssettsetsset )
	# 1. FreeBSD sh; 2. bosh
		if thisshellhas QRK_HDPARQUOT; then
			okmsg=QRK_HDPARQUOT
			return 0
		else
			failmsg='QRK_HDPARQUOT not detected'
			return 1
		fi ;;
	( 12345678ttssttss \
	| 1\'2\'3\'4\'5\'6\'7\'8\'ttssttss \
	| 1\'2\'3\'4\'5\'6\'7\'8\'tsetssettsetsset )
	# 1. yash; 2. bash, dash, ksh93, zsh; 3. pdksh/mksh/lksh
		if thisshellhas QRK_HDPARQUOT; then
			failmsg='QRK_HDPARQUOT wrongly detected'
			return 1
		else
			return 0
		fi ;;
	esac
	failmsg="unknown quirk/bug [$foo$bar]"
	return 1
}

doTest12() {
	title="trimming of IFS whitespace by 'read'"
	# Regression test for BUG_READTWHSP.
	# (NOTE: in here-document below: two leading spaces and two trailing spaces!)
	IFS=' ' read foo <<-EOF
	  ab  cd  
	EOF
	case $foo in
	('ab  cd')	if thisshellhas BUG_READTWHSP; then
				failmsg='BUG_READTWHSP wrongly detected'
				return 1
			else
				return 0
			fi ;;
	('ab  cd  ')	if thisshellhas BUG_READTWHSP; then
				xfailmsg=BUG_READTWHSP
				return 2
			else
				failmsg='BUG_READTWHSP not detected'
				return 1
			fi ;;
	esac
	failmsg="[$foo]"
	return 1
}

doTest13() {
	title='line continuation in expanding here-doc'
	# regression test for BUG_HDOCBKSL detection
	FIN() {
		:
	}
	command eval 'v=$(cat <<-FIN'$CCn$CCt'def \'$CCn$CCt'ghi'$CCn$CCt'jkl\'$CCn$CCt'FIN'$CCn$CCt'FIN'$CCn')'
	unset -f FIN
	case $v in
	( 'def '$CCt'ghi'$CCn'jkl'$CCt'FIN' )
		return 0 ;;
	( 'def ghi'$CCn'jkl' )  # zsh up to 5.4.2
		if thisshellhas BUG_HDOCBKSL; then
			xfailmsg=BUG_HDOCBKSL
			return 2
		else
			failmsg='BUG_HDOCBKSL not detected'
			return 1
		fi ;;
	( * )	failmsg='unknown bug'
		return 1 ;;
	esac
}

doTest14() {
	title='double quotes properly deactivate glob'
	# regression test for BUG_DQGLOB
	case \\foo in
	( "\*" )
		case \\fx in
		( "\?x" )
			if thisshellhas BUG_DQGLOB; then
				xfailmsg=BUG_DQGLOB
				return 2
			else
				failmsg='BUG_DQGLOB not detected'
				return 1
			fi ;;
		( * )	failmsg='unknown variant of BUG_DQGLOB'
			return 1 ;;
		esac ;;
	( "\foo" )
		not thisshellhas BUG_DQGLOB ;;
	( * )	failmsg='unknown bug'
		return 1 ;;
	esac
}

lastTest=14
