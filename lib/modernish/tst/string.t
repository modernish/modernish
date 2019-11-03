#! test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# Regression tests related to string and text processing.

TEST title="whitespace/non-whitespace IFS delimiters"
	IFS=': '
	v='  ::  \on\e :\tw'\''o \th\'\''re\e :\\'\''fo\u\r:   : :  '
	set -- $v
	IFS=
	v=${#},${1-U},${2-U},${3-U},${4-U},${5-U},${6-U},${7-U},${8-U},${9-U},${10-U},${11-U},${12-U}
	case $v in
	( '8,,,\on\e,\tw'\''o,\th\'\''re\e,\\'\''fo\u\r,,,U,U,U,U' )
		mustNotHave QRK_IFSFINAL ;;
	( '9,,,\on\e,\tw'\''o,\th\'\''re\e,\\'\''fo\u\r,,,,U,U,U' )
		mustHave QRK_IFSFINAL ;;
	( '11,,,\on\e,,\tw'\''o,\th\'\''re\e,,\\'\''fo\u\r,,,,U,' )
		# pdksh
		failmsg="incorrect IFS whitespace removal"
		return 1 ;;
	( '9,,,on\e,tw'\''o,th\'\''re\e,\'\''fo\u\r,,,,U,U,U,' )
		# yash 2.8 to 2.37
		failmsg=="split eats initial backslashes"
		return 1 ;;
	( '9,,,\on\e,\tw'\''o,\th\'\''re\e,\'\''fo\u\r,,,,U,U,U,' )
		# zsh up to 4.2.6
		failmsg="split eats first of double backslash"
		return 1 ;;
	( '8,,\on\e,\tw'\''o,\th\'\''re\e,\\'\''fo\u\r,,,,U,U,U,U,' )
		# ksh93 Version M 1993-12-28 p
		# Bug with IFS whitespace: an initial empty whitespace-separated field
		# appears at the end of the expansion result instead of the start
		# if IFS contains both whitespace and non-whitespace characters.
		failmsg="split moves empty field to end of expansion"
		return 1 ;;
	( '7,::,\on\e,:\tw'\''o,\th\'\''re\e,:\\'\''fo\u\r:,:,:,U,U,U,U,U,' )
		# ksh93 with a DEBUG trap set
		failmsg="non-whitespace ignored in split"
		return 1 ;;
	( '1,  ::  \on\e :\tw'\''o \th\'\''re\e :\\'\''fo\u\r:   : :  ,U,U,U,U,U,U,U,U,U,U,U,' )
		failmsg="no split (native zsh?)"
		return 1 ;;
	( * )	return 1 ;;
	esac
ENDT

TEST title='tolower (ASCII)'
	v=ABCDEFGHIJKLMNOPQRSTUVWXYZ
	tolower v
	str eq $v abcdefghijklmnopqrstuvwxyz
ENDT

TEST title='toupper (ASCII)'
	v=abcdefghijklmnopqrstuvwxyz
	toupper v
	str eq $v ABCDEFGHIJKLMNOPQRSTUVWXYZ
ENDT

TEST title='tolower (UTF-8)'
	utf8Locale || return
	v='ABCDÉFĲN_ΑΒΓΔΕΖ_АБВГДЕ_ԱԲԳԴԵԶ'
	tolower v
	case $v in
	( 'abcdéfĳn_αβγδεζ_абвгде_աբգդեզ' )
		not isset MSH_2UP2LOW_NOUTF8 ;;
	( 'abcdÉfĲn_ΑΒΓΔΕΖ_АБВГДЕ_ԱԲԳԴԵԶ' )
		xfailmsg='no UTF-8'
		isset MSH_2UP2LOW_NOUTF8 && return 2 ;;
	( * )	return 1 ;;
	esac
ENDT

TEST title='toupper (UTF-8)'
	utf8Locale || return
	v='abcdéfĳn_αβγδεζ_абвгде_աբգդեզ'
	toupper v
	case $v in
	( 'ABCDÉFĲN_ΑΒΓΔΕΖ_АБВГДЕ_ԱԲԳԴԵԶ' )
		not isset MSH_2UP2LOW_NOUTF8 ;;
	( 'ABCDéFĳN_αβγδεζ_абвгде_աբգդեզ' )
		xfailmsg='no UTF-8'
		isset MSH_2UP2LOW_NOUTF8 && return 2 ;;
	( * )	return 1 ;;
	esac
ENDT

TEST title='backslash in nonexpanding here-document'
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
ENDT

TEST title='single-quoted pattern in param subst'
	v="${CCn}one${CCt}two'three/four'five"
	case "${v#${CCn}'one'${CCt}'two'\''three'}" in
	( "/four'five" )
		mustNotHave BUG_PSUBSQUOT ;;
	( "$v" )
		mustHave BUG_PSUBSQUOT ;;
	( * )	return 1 ;;
	esac
ENDT

TEST title='quoting within param subst in here-doc'

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
ENDT

TEST title="trimming of IFS whitespace by 'read'"

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
	( * )	failmsg="[$v]"
		return 1 ;;
	esac
ENDT

TEST title='line continuation in expanding here-doc'
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
ENDT

TEST title='double quotes properly deactivate glob'
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
ENDT

TEST title='trim quoted pattern in here-doc'
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
ENDT

TEST title='here-doc can be read regardless of umask'
	# note: 'umask 777' is active in the test suite: zero perms
	{
		command : <<-EOF
		EOF
	} 2>/dev/null
	case $? in
	( 0 )	mustNotHave BUG_HDOCMASK ;;
	( * )	mustHave BUG_HDOCMASK ;;
	esac
ENDT

TEST title='newlines from expansion in param subst'
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
ENDT

TEST title='literal newlines in param subst'
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
ENDT

TEST title='additive string assignment'
	v=foo
	{ v=$(	MSH_NOT_FOUND_OK=y
		v+=bar$v 2>/dev/null
		putln $v
	); }
	case $v in
	( foo )	mustNotHave ADDASSIGN && return 3;;
	( foobarfoo )
		mustHave ADDASSIGN ;;
	( * )	return 1 ;;
	esac
ENDT

TEST title='glob patterns work for all values of IFS'
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
ENDT

TEST title='multibyte UTF-8 char can be IFS char'
	utf8Locale || return

	# test field splitting
	push IFS
	IFS='£'			# £ = C2 A3
	v='abc§def ghi§jkl'	# § = C2 A7 (same initial byte)
	set -- $v
	pop IFS
	v=${#},${1-},${2-},${3-}
	case $v in
	( '1,abc§def ghi§jkl,,' )
		;; # continue below
	( * )	w=$(printf '\247')	# second byte of § (A7)
		case $v in
		( "1,abc${w}def ghi${w}jkl,," | "3,abc,${w}def ghi,${w}jkl" )  # ksh93 | mksh, FreeBSD sh
			mustHave WRN_MULTIBYTE
			ne v=$? 1 && return $v
			mustHave BUG_MULTIBIFS
			return ;;
		( * )	return 1 ;;
		esac ;;
	esac

	# test "$*"
	push IFS
	IFS='§'
	set -- 'abc' 'def ghi' 'jkl'
	v="$*"			# BUG_PP_* compat: quote
	pop IFS
	case $v in
	( 'abc§def ghi§jkl' )
		mustNotHave WRN_MULTIBYTE && mustNotHave BUG_MULTIBIFS ;;
	( abc?def\ ghi?jkl )
		mustHave WRN_MULTIBYTE
		ne v=$? 1 && return $v
		mustHave BUG_MULTIBIFS ;;
	( * )	return 1 ;;
	esac
ENDT

TEST title='${var+set}'
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
ENDT

TEST title='${var:+nonempty}'
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
ENDT

TEST title='${var-unset}'
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
ENDT

TEST title='${var:-empty}'
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
ENDT

TEST title="pattern is not matched as literal string"
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
ENDT

TEST title="'case' matches escaped literal ctl chars"
	# bash 2.05b, 3.0 and 3.1 have bugs with literal $CC01 and $CC7F, but test them all
	# (except linefeed which signifies line continuation so would be removed when escaped).
	IFS=
	for v in	    $CC02 $CC03 $CC04 $CC05 $CC06 $CC07 $CC08 $CC09       $CC0B $CC0C $CC0D $CC0E $CC0F \
		$CC10 $CC11 $CC12 $CC13 $CC14 $CC15 $CC16 $CC17 $CC18 $CC19 $CC1A $CC1B $CC1C $CC1D $CC1E $CC1F
	do
		eval 	'case ${CC01}a${CC7F}b${v}X${CC01}c${CC7F} in' \
			"( \\${CC01}\\a\\${CC7F}\\b\\${v}\\X\\${CC01}\\c\\${CC7F} )" \
			'	;;' \
			'( * )	return 1 ;;' \
			'esac'
	done
ENDT

TEST title="'case' handles empty bracket expressions"
	# Empty bracket expressions such as [] or v=; [$v] should always be a non-match.
	# FTL_EMPTYBRE causes [] | [] to be taken as a single bracket expression: ["] | ["].
	case ] in
	( [] | [] )
		failmsg=FTL_EMPTYBRE; return 1 ;;
	( []] )	;;
	( * )	return 1 ;;
	esac
ENDT

TEST title="'case' handles unbalanced parenthesis"
	v=ini
	{ v=$(	eval 'v=$(
			case $v in
			foo )	/dev/null/bar ;;
			( baz )	/dev/null/quux ;;
			ini )	putln OK ;;
			* )	putln WRONG ;;
			esac
		)'
		putln $v
	); } 2>/dev/null
	case $v in
	( OK )	mustNotHave BUG_CASEPAREN ;;
	( ini )	mustHave BUG_CASEPAREN ;;
	( * )	failmsg="v=$v"; return 1 ;;
	esac
ENDT

TEST title='bracket expressions support char classes'
	case / in
	( [[:punct:]] )
		mustNotHave BUG_NOCHCLASS ;;
	( * )	mustHave BUG_NOCHCLASS ;;
	esac
ENDT

TEST title='quoted param expansion handles escaped }'
	unset -v v
	v="${v-ab\}cd\}ef\}gh}"
	case $v in
	( 'ab\}cd\}ef\}gh' )
		mustHave BUG_PSUBBKSL1 ;;
	( 'ab}cd}ef}gh' )
		mustNotHave BUG_PSUBBKSL1 ;;
	( * )	return 1 ;;
	esac
ENDT

TEST title='shell assignments are independent of IFS'
	IFS="d ${CC01}b${CCt}c${CCn}d"
	v=d${CCn}c${CC01}b${CCt}a
	v=$v	# trigger BUG_ASGNCC01
	IFS=
	case $v in
	( d${CCn}c${CC01}b${CCt}a )
		mustNotHave BUG_ASGNCC01 ;;
	( d${CCn}cb${CCt}a )
		mustHave BUG_ASGNCC01 ;;
	( * )	return 1 ;;
	esac
ENDT

TEST title='empty removal of unqoted unset variables'
	v=a
	w=
	unset -v x
	set +u
	IFS=
	# test nonempty (v), empty (w), and unset (x) variables
	set $v ${v-} ${v:-} ${v+$v} ${v:+$v} $w ${w-} ${w:-} ${w+$w} ${w:+$w} $x ${x-} ${x:-} ${x+$x} ${x:+$x}
	IFS=,
	v="$*"
	IFS=
	set -u
	case $v in
	( 'a,a,a,a,a' )
		mustNotHave BUG_PSUBEMPT ;;
	( 'a,a,a,a,a,,,' )
		mustHave BUG_PSUBEMPT ;;
	( * )	return 1 ;;
	esac
ENDT

TEST title="assignment in parameter substitution"
	# Regression test for BUG_PSUBASNCC.
	unset -v foo bar
	set -- ${foo=$ASCIICHARS} "${bar=$ASCIICHARS}"
	# check that the assignment succeeds
	str eq $foo$bar $ASCIICHARS$ASCIICHARS || return 1
	# check that the parameter substitution returns identical results
	if str eq $1$2 $ASCIICHARS$ASCIICHARS; then
		mustNotHave BUG_PSUBASNCC
		return
	fi
	# if not, check for BUG_PSUBASNCC
	foo=$ASCIICHARS; replacein foo $CC01 ''; replacein foo $CC7F ''
	bar=$ASCIICHARS; replacein bar $CC01 ''
	str eq $1,$2 $foo,$bar && mustHave BUG_PSUBASNCC
ENDT

TEST title="str lt/gt: sorts before/after"
	str lt abcd efgh && str gt EFGH ABCD
ENDT

TEST title="closing brace does not terminate string"
	# this was a bug in dash-git, fixed in commit 878514712c5
	v=vvv
	v=12${#v}45
	str eq $v 12345
ENDT
