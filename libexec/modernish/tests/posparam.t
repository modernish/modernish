#! test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# Tests for the positional parameters ($@ and $*). This is to discover any
# shell bugs that modernish doesn't know about yet; the fact that modernish
# doesn't know about it should be considered a bug in modernish.
#
# Most of these tests were inspired by the examples in the POSIX rationale,
# section 2.5.2, Special Parameters:
# http://pubs.opengroup.org/onlinepubs/9699919799/xrat/V4_xcu_chap02.html#tag_23_02_05_02
# which is a supplement to the main spec:
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_05_02

doTest1() {
	title='$*, IFS is space'
	set "abc" "def ghi" "jkl"
	IFS=' '
	set $*
	IFS=
	eq $# 4 && identic "$1|$2|$3|$4" "abc|def|ghi|jkl"
}

doTest2() {
	title='"$*", IFS is space'
	set "abc" "def ghi" "jkl"
	IFS=' '
	set "$*"
	IFS=
	eq $# 1 && identic "$1" "abc def ghi jkl"
}

doTest3() {
	title='$* concatenated, IFS is space'
	set "abc" "def ghi" "jkl"
	IFS=' '
	set xx$*yy
	IFS=
	eq $# 4 && identic "$1|$2|$3|$4" "xxabc|def|ghi|jklyy"
}

doTest4() {
	title='"$*" concatenated, IFS is space'
	set "abc" "def ghi" "jkl"
	IFS=' '
	set "xx$*yy"
	IFS=
	eq $# 1 && identic "$1" "xxabc def ghi jklyy"
}

doTest5() {
	title='$@, IFS is space'
	set "abc" "def ghi" "jkl"
	IFS=' '
	set $@
	IFS=
	case ${#},${1-},${2-},${3-},${4-NONE} in
	( '4,abc,def,ghi,jkl' )
		mustNotHave BUG_PP_06 ;;
	( '3,abc,def ghi,jkl,NONE' )
		mustHave BUG_PP_06 ;;
	( * )	return 1 ;;
	esac
}

doTest6() {
	title='$@, IFS set/empty'
	set "abc" "def ghi" "jkl"
	IFS=
	set $@
	case ${#},${1-},${2-NONE},${3-NONE} in
	( '3,abc,def ghi,jkl' )
		mustNotHave BUG_PP_08 ;;
	( '1,abcdef ghijkl,NONE,NONE' )
		mustHave BUG_PP_08 ;;
	( * )	return 1 ;;
	esac
}

doTest7() {
	title='"$@", IFS set/empty'
	set "abc" "def ghi" "jkl"
	IFS=
	set "$@"
	eq $# 3 && identic "$1|$2|$3" "abc|def ghi|jkl"
}

doTest8() {
	title='${1+"$@"}, IFS set/empty'
	set "abc" "def ghi" "jkl"
	IFS=
	set ${1+"$@"}
	failmsg="$#|${1-}|${2-}|${3-}"
	case ${#},${1-},${2-NONE},${3-NONE} in
	( '3,abc,def ghi,jkl')
		mustNotHave BUG_PP_1ARG ;;
	( '1,abcdef ghijkl,NONE,NONE' )
		mustHave BUG_PP_1ARG ;;
	( * )	return 1 ;;
	esac
}

doTest9() {
	title='${novar-"$@"}, IFS set/empty'
	set "abc" "def ghi" "jkl"
	unset -v novar
	IFS=
	set ${novar-"$@"}
	case ${#},${1-},${2-NONE},${3-NONE} in
	( '3,abc,def ghi,jkl')
		mustNotHave BUG_PP_1ARG ;;
	( '1,abcdef ghijkl,NONE,NONE' )
		mustHave BUG_PP_1ARG ;;
	( * )	return 1 ;;
	esac
}

doTest10() {
	title='$@ concatenated, IFS is space'
	set "abc" "def ghi" "jkl"
	IFS=' '
	set xx$@yy
	IFS=
	case ${#},${1-},${2-},${3-},${4-NONE} in
	( '4,xxabc,def,ghi,jklyy' )
		mustNotHave BUG_PP_06 ;;
	( '3,xxabc,def ghi,jklyy,NONE' )
		mustHave BUG_PP_06 ;;
	( * )	return 1 ;;
	esac
}

doTest11() {
	title='"$@" concatenated, IFS set/empty'
	set "abc" "def ghi" "jkl"
	set "xx$@yy"
	eq $# 3 && identic "$1|$2|$3" "xxabc|def ghi|jklyy"
}

doTest12() {
	title='$@$@, IFS is space'
	set "abc" "def ghi" "jkl"
	IFS=' '
	set $@$@
	IFS=
	case ${#},${1-},${2-},${3-},${4-},${5-},${6-NONE},${7-NONE} in
	( '7,abc,def,ghi,jklabc,def,ghi,jkl' )
		mustNotHave BUG_PP_06 ;;
	( '5,abc,def ghi,jklabc,def ghi,jkl,NONE,NONE' )
		mustHave BUG_PP_06 ;;
	( * )	return 1 ;;
	esac
}

doTest13() {
	title='"$@$@", IFS set/empty'
	set "abc" "def ghi" "jkl"
	set "$@$@"
	eq $# 5 && identic "$1|$2|$3|$4|$5" "abc|def ghi|jklabc|def ghi|jkl"
}

# ... IFS=":" ...

doTest14() {
	title='"$*", IFS is ":"'
	set "abc" "def ghi" "jkl"
	IFS=':'
	set "$*"
	IFS=
	eq $# 1 && identic "$1" "abc:def ghi:jkl"
}

doTest15() {
	title='var=$*, IFS is ":"'
	set "abc" "def ghi" "jkl"
	IFS=':'
	var=$*
	IFS=
	identic "$var" "abc:def ghi:jkl" || return

	set -- "$ASCIICHARS" "$ASCIICHARS" "$ASCIICHARS"
	IFS=':'
	var=$*
	IFS=
	v=$CC01${CONTROLCHARS%$CC7F}$CC01$CC7F${ASCIICHARS#$CONTROLCHARS}
	case $var in
	( "$v:$v:$v" )
		mustHave BUG_PP_10A ;;
	( "$ASCIICHARS:$ASCIICHARS:$ASCIICHARS" )
		mustNotHave BUG_PP_10A ;;
	( * )	return 1 ;;
	esac
}

doTest16() {
	title='var="$*", IFS is ":"'
	set "abc" "def ghi" "jkl"
	IFS=':'
	var="$*"
	IFS=
	identic "$var" "abc:def ghi:jkl"
}

doTest17() {
	title='${var-$*}, IFS is ":"'
	set "abc" "def ghi" "jkl"
	unset -v var
	IFS=':'
	set ${var-$*}
	IFS=
	case ${#},${1-},${2-NONE},${3-NONE} in
	( '3,abc,def ghi,jkl' )
		mustNotHave BUG_PP_09 ;;
	( '1,abc def ghi jkl,NONE,NONE' )
		mustHave BUG_PP_09 ;;	# bash 2
	( * )	return 1 ;;
	esac
}

doTest18() {
	title='"${var-$*}", IFS is ":"'
	set "abc" "def ghi" "jkl"
	unset -v var
	IFS=':'
	set "${var-$*}"
	IFS=
	eq $# 1 && identic "$1" "abc:def ghi:jkl"
}

doTest19() {
	title='${var-"$*"}, IFS is ":"'
	set "abc" "def ghi" "jkl"
	unset -v var
	IFS=':'
	set ${var-"$*"}
	IFS=
	eq $# 1 && identic "$1" "abc:def ghi:jkl"
}

doTest20() {
	title='${var=$*}, IFS is ":"'
	set "abc" "def ghi" "jkl"
	unset -v var
	IFS=':'
	set ${var=$*}
	IFS=
	case ${#},${1-},${2-NONE},${3-NONE},var=$var in
	( '3,abc,def ghi,jkl,var=abc:def ghi:jkl' )
		mustNotHave BUG_PP_04E ;;
	( '1,abc def ghi jkl,NONE,NONE,var=abc def ghi jkl' )
		mustHave BUG_PP_04E ;;		# bash 4.3.30
	( * )	return 1 ;;
	esac
}

doTest21() {
	title='"${var=$*}", IFS is ":"'
	set "abc" "def ghi" "jkl"
	unset -v var
	IFS=':'
	set "${var=$*}"
	IFS=
	eq $# 1 && identic "$1|var=$var" "abc:def ghi:jkl|var=abc:def ghi:jkl"
}

# ... IFS='' ...

doTest22() {
	title='var=$*, IFS set/empty'
	set "abc" "$ASCIICHARS" "def ghi" "$ASCIICHARS" "jkl"
	IFS=
	var=$*
	v=${CONTROLCHARS#$CC01}
	v=${v%$CC7F}${ASCIICHARS#$CONTROLCHARS}
	case $var in
	( "abc${ASCIICHARS}def ghi${ASCIICHARS}jkl" )
		mustNotHave BUG_PP_03 && mustNotHave BUG_PP_10 ;;
	( "abc${v}def ghi${v}jkl" )
		mustNotHave BUG_PP_03 && mustHave BUG_PP_10 ;;
	( "abc" )
		mustNotHave BUG_PP_10 && mustHave BUG_PP_03 ;;
	( * )	return 1 ;;
	esac
}

doTest23() {
	title='var="$*", IFS set/empty'
	set "abc" "$ASCIICHARS" "def ghi" "$ASCIICHARS" "jkl"
	IFS=
	var="$*"
	identic "$var" "abc${ASCIICHARS}def ghi${ASCIICHARS}jkl"
}

doTest24() {
	title='${var-$*}, IFS set/empty'
	set "abc" "def ghi" "jkl"
	unset -v var
	IFS=
	set ${var-$*}
	case ${#},${1-},${2-NONE},${3-NONE} in
	( '3,abc,def ghi,jkl' )
		mustNotHave BUG_PP_08B ;;
	( '1,abcdef ghijkl,NONE,NONE' | '1,abc def ghi jkl,NONE,NONE' )
		mustHave BUG_PP_08B ;;	# bash | pdksh/bosh
	( * )	return 1 ;;
	esac
}

doTest25() {
	title='"${var-$*}", IFS set/empty'
	set "abc" "def ghi" "jkl"
	unset -v var
	IFS=
	set "${var-$*}"
	eq $# 1 && identic "$1" "abcdef ghijkl"
}

doTest26() {
	title='${var-"$*"}, IFS set/empty'
	set "abc" "def ghi" "jkl"
	unset -v var
	IFS=
	set ${var-"$*"}
	eq $# 1 && identic "$1" "abcdef ghijkl"
}

doTest27() {
	title='${var=$*}, IFS set/empty'
	set "abc" "def ghi" "jkl"
	unset -v var
	IFS=
	set ${var=$*}
	case ${#},${1-},${2-NONE},${3-NONE},var=$var in
	( '1,abcdef ghijkl,NONE,NONE,var=abcdef ghijkl' )
		mustNotHave BUG_PP_04 && mustNotHave BUG_PP_04_S ;;
	( '3,abc,def ghi,jkl,var=jkl' )
		mustNotHave BUG_PP_04_S && mustHave BUG_PP_04 ;;	# pdksh/mksh
	( '2,abcdef,ghijkl,NONE,var=abcdef ghijkl' )
		mustNotHave BUG_PP_04 && mustHave BUG_PP_04_S ;;	# bash 4.2, 4.3
	( * )	return 1 ;;
	esac
}

doTest28() {
	title='"${var=$*}", IFS set/empty'
	set "abc" "def ghi" "jkl"
	unset -v var
	IFS=
	set "${var=$*}"
	eq $# 1 && identic "$1|var=$var" "abcdef ghijkl|var=abcdef ghijkl"
}

# ... IFS unset ...

doTest29() {
	title='"$*", IFS unset'
	set "abc" "def ghi" "jkl"
	unset -v IFS
	set "$*"
	IFS=
	eq $# 1 && identic "$1" "abc def ghi jkl"
}

doTest30() {
	title='var=$*, IFS unset'
	set "abc" "def ghi" "jkl"
	unset -v IFS
	var=$*
	IFS=
	case $var in
	( 'abc def ghi jkl' )
		# *may* have BUG_PP_03 variant with set & empty IFS (mksh)
		;;
	( 'abc' )
		mustHave BUG_PP_03 ;;
	( * )	return 1 ;;
	esac
}

doTest31() {
	title='var="$*", IFS unset'
	set "abc" "def ghi" "jkl"
	unset -v IFS
	var="$*"
	IFS=
	identic "$var" "abc def ghi jkl"
}

doTest32() {
	title='${var-$*}, IFS unset'
	set "abc" "def ghi" "jkl"
	unset -v var
	unset -v IFS
	set ${var-$*}
	IFS=
	case ${#},${1-},${2-},${3-},${4-NONE} in
	( '4,abc,def,ghi,jkl' )
		mustNotHave BUG_PP_07 ;;
	( '3,abc,def ghi,jkl,NONE' )
		mustHave BUG_PP_07 ;;	# zsh
	( * )	return 1 ;;
	esac
}

doTest33() {
	title='"${var-$*}", IFS unset'
	set "abc" "def ghi" "jkl"
	unset -v var
	unset -v IFS
	set "${var-$*}"
	IFS=
	eq $# 1 && identic "$1" "abc def ghi jkl"
}

doTest34() {
	title='${var-"$*"}, IFS unset'
	set "abc" "def ghi" "jkl"
	unset -v var
	unset -v IFS
	set ${var-"$*"}
	IFS=
	eq $# 1 && identic "$1" "abc def ghi jkl"
}

doTest35() {
	title='${var=$*}, IFS unset'
	set "abc" "def ghi" "jkl"
	unset -v var
	unset -v IFS
	set ${var=$*}
	IFS=
	eq $# 4 && identic "$1|$2|$3|$4|var=$var" "abc|def|ghi|jkl|var=abc def ghi jkl"
}

doTest36() {
	title='"${var=$*}", IFS unset'
	set "abc" "def ghi" "jkl"
	unset -v var
	unset -v IFS
	set "${var=$*}"
	IFS=
	eq $# 1 && identic "$1|var=$var" "abc def ghi jkl|var=abc def ghi jkl"
}

doTest37() {
	title='"$@", IFS unset'
	set "abc" "def ghi" "jkl"
	unset -v IFS
	set "$@"
	IFS=
	eq $# 3 && identic "$1|$2|$3" "abc|def ghi|jkl"
}

# ...empty fields...

doTest38() {
	title='$* with empty field, IFS unset'
	set "one" "" "three"
	unset -v IFS
	set $*
	IFS=
	case ${#},${1-},${2-},${3-NONE} in
	( '2,one,three,NONE' )
		mustNotHave QRK_EMPTPPFLD ;;
	( '3,one,,three' )
		mustHave QRK_EMPTPPFLD ;;
	( * )	return 1 ;;
	esac
}

doTest39() {
	title='$@ with empty field, IFS unset'
	set "one" "" "three"
	unset -v IFS
	set $@
	IFS=
	case ${#},${1-},${2-},${3-NONE} in
	( '2,one,three,NONE' )
		mustNotHave QRK_EMPTPPFLD ;;
	( '3,one,,three' )
		mustHave QRK_EMPTPPFLD ;;
	( * )	return 1 ;;
	esac
}

# ...concatenating empty PPs...

doTest40() {
	title='empty "$*", IFS set/empty'
	set --
	IFS=
	set foo "$*"
	eq $# 2 && identic "$1|$2" "foo|"
}

doTest41() {
	title='empty "${novar-}$*$(:)", IFS set/empty'
	set --
	unset -v novar
	IFS=
	set foo "${novar-}$*$(:)"
	eq $# 2 && identic "$1|$2" "foo|"
}

doTest42() {
	title='empty $@ and $*, IFS set/empty'
	set --
	IFS=
	set foo $@ $*
	set $@ $*
	set $@ $*
	case ${#},${1-},${2-U},${3-U},${4-U},${5-U},${6-U},${7-U},${8-U},${9-U},${10-U},${11-U},${12-U} in
	( '4,foo,foo,foo,foo,U,U,U,U,U,U,U,U' )
		mustNotHave BUG_PP_05 && mustNotHave BUG_PP_08 ;;
	( '12,foo,,,foo,,,foo,,,foo,,' )
		mustNotHave BUG_PP_08 && mustHave BUG_PP_05 ;;
	( '2,foofoo,foofoo,U,U,U,U,U,U,U,U,U,U' )
		mustNotHave BUG_PP_05 && mustHave BUG_PP_08 ;;
	( * )	return 1 ;;
	esac
}

doTest43() {
	title='empty "$@", IFS set/empty'
	set --
	IFS=
	set foo "$@"
	eq $# 1
}

doTest44() {
	title="empty ''\$@, IFS set/empty"
	set --
	IFS=
	set foo ''$@
	case ${#},${1-},${2-NONE} in
	( '2,foo,' )
		mustNotHave BUG_PP_02 ;;
	( '1,foo,NONE' )
		mustHave BUG_PP_02 ;;
	( * )	return 1 ;;
	esac
}

doTest45() {
	title="empty ''\"\$@\", IFS set/empty"
	set --
	IFS=
	set foo ''"$@"
	case ${#},${1-},${2-NONE} in
	( '2,foo,' )
		mustNotHave BUG_PP_01 ;;
	( '1,foo,NONE' )
		mustHave BUG_PP_01 ;;
	( * )	return 1 ;;
	esac
}

doTest46() {
	title='empty "${novar-}$@$(:)", IFS set/empty'
	set --
	unset -v novar
	IFS=
	set foo "${novar-}$@$(:)"
	case ${#},${1-},${2-NONE} in
	( '2,foo,' )
		mustNotHave QRK_EMPTPPWRD ;;
	( '1,foo,NONE' )
		mustHave QRK_EMPTPPWRD ;;
	( * )	return 1 ;;
	esac
}

doTest47() {
	title='empty '\'\''"${novar-}$@$(:)", IFS set/empty'
	set --
	unset -v novar
	IFS=
	set foo ''"${novar-}$@$(:)"
	case ${#},${1-},${2-NONE} in
	( '2,foo,' )
		mustNotHave BUG_PP_01 ;;
	( '1,foo,NONE' )
		mustHave BUG_PP_01 ;;
	( * )	return 1 ;;
	esac
}

# ... shell grammar parsing ...

doTest48() {
	title='correct parsing of $#'
	set 1 2 3
	foo=$$
	case $#$foo,$(($#-1+1)) in
	( "3$foo,3" )
		;;
	( "${#foo}foo,${#-}2" | "${#foo}foo,2" )
		failmsg=FTL_HASHVAR; return 1 ;;
	( * )	return 1 ;;
	esac
}

doTest49() {
	title='quoting $* quotes IFS wildcards (1)'
	IFS=*	# on bash < 4.4, BUG_IFSGLOBC now breaks 'case' and hence all of modernish
	set "abc" "def ghi" "jkl"
	case abcFOOBARdef\ ghiBAZQUXjkl in
	("$*")	IFS=; mustHave BUG_IFSGLOBS; return ;;	# ksh93
	( * )	IFS=; mustNotHave BUG_IFSGLOBS; return ;;
	esac
	# if not even '*' matched, we've got BUG_IFSGLOBC
	IFS=	# unbreak modernish on bash < 4.4
	mustNotHave BUG_IFSGLOBS && mustHave BUG_IFSGLOBC
}

doTest50() {
	title='quoting $* quotes IFS wildcards (2)'
	IFS=*	# on bash < 4.4, BUG_IFSGLOBC now breaks 'case' and hence all of modernish
	set "abc" "def ghi" "jkl"
	v=abcFOOBARdef\ ghiBAZQUXjklBUG
	v=${v#"$*"}
	IFS=	# unbreak modernish on bash < 4.4
	case $v in
	( BUG )	mustHave BUG_IFSGLOBS; return ;;
	( abcFOOBARdef\ ghiBAZQUXjklBUG )
		mustNotHave BUG_IFSGLOBS; return ;;
	esac
	return 1
}

doTest51() {
	title='quoted "$@" expansion is indep. of IFS'
	set "abc" "def ghi" "jkl"
	IFS=$CC01
	set "$@"
	IFS=,
	v="$*"
	IFS=
	if eq $# 1 && identic $v "abc${CC01}def ghi${CC01}jkl"; then
		mustHave BUG_IFSCC01PP	# bash <= 3.2
	elif eq $# 27 && identic $v ",,a,,b,,c${CC7F},,d,,e,,f,, ,,g,,h,,i${CC7F},,j,,k,,l"; then
		mustHave BUG_IFSCC01PP	# bash 4.0 - 4.3
	else
		eq $# 3 && identic $v "abc,def ghi,jkl"
	fi
}

doTest52() {
	title='empty removal of unqoted nonexistent PPs'
	set "a" ""
	set +u
	IFS=
	# test nonempty (1), empty (2), and unset (3) PPs
	set $1 ${1-} ${1:-} ${1+$1} ${1:+$1} $2 ${2-} ${2:-} ${2+$2} ${2:+$2} $3 ${3-} ${3:-} ${3+$3} ${3:+$3}
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
}

doTest53() {
	title='"${1+$@}", IFS set/empty'
	set "abc" "def ghi" "jkl"
	IFS=
	set "${1+$@}"
	failmsg="$#|${1-}|${2-}|${3-}"
	case ${#},${1-},${2-NONE},${3-NONE} in
	( '3,abc,def ghi,jkl')
		mustNotHave BUG_PP_1ARG ;;
	( '1,abcdef ghijkl,NONE,NONE' )
		mustHave BUG_PP_1ARG ;;
	( * )	return 1 ;;
	esac
}


lastTest=53
