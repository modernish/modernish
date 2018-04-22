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

doTest5() {
	title='tolower on variable (UTF-8)'
	utf8Locale || return
	v='ABCDÉFĲN_ΑΒΓΔΕΖ_АБВГДЕ_ԱԲԳԴԵԶ'
	tolower v
	case $v in
	( 'abcdéfĳn_αβγδεζ_абвгде_աբգդեզ' )
		mustNotHave WRN_2UP2LOW ;;
	( 'abcdÉfĲn_ΑΒΓΔΕΖ_АБВГДЕ_ԱԲԳԴԵԶ' )
		mustHave WRN_2UP2LOW ;;
	( * )	return 1 ;;
	esac
}

doTest6() {
	title='toupper on variable (UTF-8)'
	utf8Locale || return
	v='abcdéfĳn_αβγδεζ_абвгде_աբգդեզ'
	toupper v
	case $v in
	( 'ABCDÉFĲN_ΑΒΓΔΕΖ_АБВГДЕ_ԱԲԳԴԵԶ' )
		mustNotHave WRN_2UP2LOW ;;
	( 'ABCDéFĳN_αβγδεζ_абвгде_աբգդեզ' )
		mustHave WRN_2UP2LOW ;;
	( * )	return 1 ;;
	esac
}

doTest7() {
	title='tolower in pipe (UTF-8)'
	utf8Locale || return
	v=$(put 'ABCDÉFĲN_ΑΒΓΔΕΖ_АБВГДЕ_ԱԲԳԴԵԶ' | tolower)
	case $v in
	( 'abcdéfĳn_αβγδεζ_абвгде_աբգդեզ' )
		mustNotHave WRN_2UP2LOW ;;
	( 'abcdÉfĲn_ΑΒΓΔΕΖ_АБВГДЕ_ԱԲԳԴԵԶ' )
		mustHave WRN_2UP2LOW ;;
	( * )	return 1 ;;
	esac
}

doTest8() {
	title='toupper in pipe (UTF-8)'
	utf8Locale || return
	v=$(put 'abcdéfĳn_αβγδεζ_абвгде_աբգդեզ' | toupper)
	case $v in
	( 'ABCDÉFĲN_ΑΒΓΔΕΖ_АБВГДЕ_ԱԲԳԴԵԶ' )
		mustNotHave WRN_2UP2LOW ;;
	( 'ABCDéFĳN_αβγδεζ_абвгде_աբգդեզ' )
		mustHave WRN_2UP2LOW ;;
	( * )	return 1 ;;
	esac
}

doTest9() {
	title='backslash in nonexpanding here-document'
	command eval 'v=$(thisshellhas BUG_HDOCMASK && umask 077
		cat <<-\EOT'$CCn$CCt'abc \'$CCn$CCt'def \\'$CCn$CCt'ghi' \
		'\\\'$CCn$CCt'jkl \\\\'$CCn$CCt'end'$CCn$CCt'EOT'$CCn$CCt')'
	case $v in
	( 'abc \'$CCn'def \\'$CCn'ghi \\\'$CCn'jkl \\\\'$CCn'end' )
		mustNotHave BUG_CSNHDBKSL ;;
	( 'abc '$CCt'def \\'$CCn'ghi \\'$CCt'jkl \\\\'$CCn'end' \
	| 'abc '$CCt'def \'$CCt'ghi \\'$CCt'jkl \\\'$CCt'end' )  # bash 2 and 3; bash 4.4
		mustHave BUG_CSNHDBKSL ;;
	( * )	return 1 ;;
	esac
}

doTest10() {
	title='single-quoted pattern in param subst'
	v="${CCn}one${CCt}two'three/four'five"
	case "${v#${CCn}'one'${CCt}'two'\''three'}" in
	( "/four'five" )
		mustNotHave BUG_PSUBSQUOT ;;
	( "$v" )
		mustHave BUG_PSUBSQUOT ;;
	( * )	return 1 ;;
	esac
}

doTest11() {
	title='quoting within param subst in here-doc'

	v=$(thisshellhas BUG_HDOCMASK && umask 077
	unset -v S U foo bar
	S=set
	# Of the test expansions below, only ${S#"se"}, ${S%"et"}, ${S##"se"} and ${S%%"et"}
	# have defined behaviour under POSIX (the double quotes must be removed).
	{ read -r foo; read -r bar; } <<-EOF
	${U-"1"}${U-'2'}${U:-"3"}${U:-'4'}${S+"5"}${S+'6'}${S:+"7"}${S:+'8'}
	${S#"se"}${S#'se'}${S%"et"}${S%'et'}${S##"se"}${S##'se'}${S%%"et"}${S%%'et'}
	EOF
	putln $foo$bar)

	case $v in
	( \"1\"\'2\'\"3\"\'4\'\"5\"\'6\'\"7\"\'8\'ttssttss \
	| \"1\"\'2\'\"3\"\'4\'\"5\"\'6\'\"7\"\'8\'tsetssettsetsset )
	# 1. FreeBSD sh; 2. bosh
		mustHave QRK_HDPARQUOT ;;
	( 12345678ttssttss \
	| 1\'2\'3\'4\'5\'6\'7\'8\'ttssttss \
	| 1\'2\'3\'4\'5\'6\'7\'8\'tsetssettsetsset )
	# 1. yash; 2. bash, dash, ksh93, zsh; 3. pdksh/mksh/lksh
		mustNotHave QRK_HDPARQUOT ;;
	( * )	failmsg="unknown quirk/bug [$foo$bar]"
		return 1 ;;
	esac
}

doTest12() {
	title="trimming of IFS whitespace by 'read'"

	v=$(thisshellhas BUG_HDOCMASK && umask 077
	# (NOTE: in here-document below: two leading spaces and two trailing spaces!)
	IFS=' ' read foo <<-EOF
	  ab  cd  
	EOF
	putln $foo)

	case $v in
	( 'ab  cd' )
		mustNotHave BUG_READWHSP ;;
	( 'ab  cd  ' )
		mustHave BUG_READWHSP ;;	# dash 0.5.7, 0.5.8
	( '  ab  cd  ' )
		mustHave BUG_READWHSP ;;	# dash 0.5.6, 0.5.6.1
	( * )	failmsg="[$v]"
		return 1 ;;
	esac
}

doTest13() {
	title='line continuation in expanding here-doc'
	FIN() {
		:
	}
	command eval 'v=$(thisshellhas BUG_HDOCMASK && umask 077
		cat <<-FIN'$CCn$CCt'def \'$CCn$CCt'ghi'$CCn$CCt'jkl\'$CCn$CCt'FIN'$CCn$CCt'FIN'$CCn')'
	unset -f FIN
	case $v in
	( 'def '$CCt'ghi'$CCn'jkl'$CCt'FIN' )
		mustNotHave BUG_HDOCBKSL ;;
	( 'def ghi'$CCn'jkl' )  # zsh up to 5.4.2
		mustHave BUG_HDOCBKSL ;;
	( * )	return 1 ;;
	esac
}

doTest14() {
	title='double quotes properly deactivate glob'
	case \\foo in
	( "\*" )
		case \\fx in
		( "\?x" )
			mustHave BUG_DQGLOB ;;
		( * )	failmsg='unknown variant of BUG_DQGLOB'
			return 1 ;;
		esac ;;
	( "\foo" )
		mustNotHave BUG_DQGLOB ;;
	( * )	return 1 ;;
	esac
}

doTest15() {
	title='trim quoted pattern in here-doc'
	v=ababcdcd
	v=$(thisshellhas BUG_HDOCMASK && umask 077
		cat <<-EOF
		${v#*ab},${v##*ab},${v%cd*},${v%%cd*}
		${v#*\a\b},${v##*\ab},${v%c\d*},${v%%\c\d*}
		${v#*"ab"},${v##*"a"b},${v%c"d"*},${v%%"cd"*}
		${v#*'ab'},${v##*'a'b},${v%c'd'*},${v%%'cd'*}
		EOF
	)
	vOK=abcdcd,cdcd,ababcd,abab
	vBUG=ababcdcd,ababcdcd,ababcdcd,ababcdcd
	case $v in
	( "$vOK$CCn$vOK$CCn$vOK$CCn$vOK" )
		mustNotHave BUG_PSUBSQHD ;;
	( "$vOK$CCn$vOK$CCn$vOK$CCn$vBUG" )
		mustHave BUG_PSUBSQHD ;;
	( * )	return 1 ;;
	esac
}

doTest16() {
	title='here-doc can be read regardless of umask'
	# note: 'umask 777' is active in the test suite: zero perms
	{
		command : <<-EOF
		EOF
	} 2>/dev/null
	case $? in
	( 0 )	mustNotHave BUG_HDOCMASK ;;
	( * )	mustHave BUG_HDOCMASK ;;
	esac
}

doTest17() {
	title='newlines from expansion in param subst'
	# Note that AT&T ksh93 does not nest quotes in parameter substitutions, so some
	# inner parts are unquoted on that shell; but the test runs with split and glob
	# disabled, so it's irrelevant. Another gotcha eliminated by 'use safe'.
	unset -v v
	for v in \
		${v-abc${CCn}def${CCn}ghi} \
		${v-abc"${CCn}"def"${CCn}"ghi} \
		${v-"abc${CCn}def${CCn}ghi"} \
		${v-"abc"${CCn}"def"${CCn}"ghi"} \
		"${v-abc${CCn}def${CCn}ghi}" \
		"${v-abc"${CCn}"def"${CCn}"ghi}" \
		"${v-"abc${CCn}def${CCn}ghi"}" \
		"${v-"abc"${CCn}"def"${CCn}"ghi"}"
	do
		case $v in
		( abc${CCn}def${CCn}ghi ) ;;
		( * ) return 1 ;;
		esac
	done
}

doTest18() {
	title='literal newlines in param subst'
	# Same test as the previous one, but with literal newlines.
	# Wrap in subshell and 'eval' for BUG_PSUBNEWLN compatibility.
	unset -v v
	( eval 'for v in \
		${v-abc
def
ghi} \
		${v-abc"
"def"
"ghi} \
		${v-"abc
def
ghi"} \
		${v-"abc"
"def"
"ghi"} \
		"${v-abc
def
ghi}" \
		"${v-abc"
"def"
"ghi}" \
		"${v-"abc
def
ghi"}" \
		"${v-"abc"
"def"
"ghi"}"
	do
		case $v in
		( abc${CCn}def${CCn}ghi ) ;;
		( * ) exit 147 ;;
		esac
	done' ) 2>/dev/null
	case $? in
	( 0 )	;;
	( 147 )	# syntax was parsed, but check failed
		return 1 ;;
	( * )	# syntax error
		mustHave BUG_PSUBNEWLN ;;
	esac
}

doTest19() {
	title='additive string assignment'
	v=foo
	{ v=$(	v+=bar$v
		putln $v
	); } 2>/dev/null
	case $v in
	( foo )	mustNotHave ADDASSIGN && return 3;;
	( foobarfoo )
		mustHave ADDASSIGN ;;
	( * )	return 1 ;;
	esac
}

doTest20() {
	title='glob patterns work for all values of IFS'
	push IFS
	IFS='?*[]'		# on bash < 4.4, BUG_IFSGLOBC now breaks 'case' and hence all of modernish
	case foo in
	( ??? )	case foo in
		( * )	case foo in
			( *[of]* )
				pop IFS
				mustNotHave BUG_IFSGLOBC
				return ;;
			esac ;;
		esac ;;
	esac
	IFS='no glob chars'	# unbreak modernish on bash < 4.4 before popping
	pop IFS
	mustHave BUG_IFSGLOBC
}

doTest21() {
	title='multibyte UTF-8 char can be IFS char'
	utf8Locale || return

	# test field splitting
	push IFS
	IFS='£'			# £ = C2 A3
	v='abc§def ghi§jkl'	# § = C2 A7 (same initial byte)
	set -- $v
	pop IFS
	case ${#},${1-},${2-},${3-} in
	( '1,abc§def ghi§jkl,,' )
		;; # continue below
	( 1,abc?def\ ghi?jkl,,	| 3,abc,?def\ ghi,?jkl )  # ksh93 | mksh
		mustHave BUG_MULTIBYTE
		ne v=$? 1 && return $v
		mustHave BUG_MULTIBIFS
		return ;;
	( * )	return 1 ;;
	esac

	# test "$*"
	push IFS
	IFS='§'
	set -- 'abc' 'def ghi' 'jkl'
	v="$*"			# BUG_PP_* compat: quote
	pop IFS
	case $v in
	( 'abc§def ghi§jkl' )
		mustNotHave BUG_MULTIBYTE && mustNotHave BUG_MULTIBIFS ;;
	( abc?def\ ghi?jkl )
		mustHave BUG_MULTIBYTE
		ne v=$? 1 && return $v
		mustHave BUG_MULTIBIFS ;;
	( * )	return 1 ;;
	esac
}

doTest22() {
	title='${var+set}'
	r=
	unset -v v
	for i in 1 2 3 4; do
		case ${v+s} in
		( s )	r=${r}s; unset -v v ;;
		( '' )	r=${r}u; v= ;;
		esac
	done
	case $r in
	(uuuu)	mustHave BUG_ISSETLOOP ;;
	(usus)	mustNotHave BUG_ISSETLOOP ;;
	( * )	return 1 ;;
	esac
}

doTest23() {
	title='${var:+nonempty}'
	r=
	v=
	for i in 1 2 3 4; do
		case ${v:+n} in
		( n )	r=${r}n; v= ;;
		( '' )	r=${r}e; v=foo ;;
		esac
	done
	case $r in
	(enen)	;;
	( * )	return 1 ;;
	esac
}

doTest24() {
	title='${var-unset}'
	r=
	unset -v v
	for i in 1 2 3 4; do
		case ${v-u} in
		( '' )	r=${r}s; unset -v v ;;
		( u )	r=${r}u; v= ;;
		esac
	done
	case $r in
	(usus)	;;
	( * )	return 1 ;;
	esac
}

doTest25() {
	title='${var:-empty}'
	r=
	v=
	for i in 1 2 3 4; do
		case ${v:-e} in
		( n )	r=${r}n; v= ;;
		( e )	r=${r}e; v=n ;;
		esac
	done
	case $r in
	(enen)	;;
	( * )	return 1 ;;
	esac
}

doTest26() {
	title="pattern is not matched as literal string"
	case [abc] in
	( [abc] )
		case [0-9] in
		( [0-9] )
			case [:alnum:] in
			( [:alnum:] )
				mustHave BUG_CASELIT
				return ;;
			esac ;;
		esac ;;
	esac
	mustNotHave BUG_CASELIT
}

lastTest=26
