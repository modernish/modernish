#! test/for/moderni/sh
# -*- mode: sh; -*-
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
	if thisshellhas BUG_PP_06; then
		xfailmsg=BUG_PP_06
		failmsg=even\ with\ $xfailmsg
		eq $# 3 && identic "$1|$2|$3" "abc|def ghi|jkl" && return 2 || return 1
	fi
	eq $# 4 && identic "$1|$2|$3|$4" "abc|def|ghi|jkl"
}

doTest6() {
	title='"$@", IFS set/empty'
	set "abc" "def ghi" "jkl"
	IFS=
	set "$@"
	eq $# 3 && identic "$1|$2|$3" "abc|def ghi|jkl"
}

doTest7() {
	title='${1+"$@"}, IFS set/empty'
	set "abc" "def ghi" "jkl"
	IFS=
	set ${1+"$@"}
	failmsg="$#|${1-}|${2-}|${3-}"
	if thisshellhas BUG_PARONEARG; then
		xfailmsg=BUG_PARONEARG
		failmsg=even\ with\ $xfailmsg
		eq $# 1 && identic "$1" "abcdef ghijkl" && return 2 || return 1
	fi
	eq $# 3 && identic "$1|$2|$3" "abc|def ghi|jkl"
}

doTest8() {
	title='${novar-"$@"}, IFS set/empty'
	set "abc" "def ghi" "jkl"
	unset -v novar
	IFS=
	set ${novar-"$@"}
	failmsg="$#|${1-}|${2-}|${3-}"
	if thisshellhas BUG_PARONEARG; then
		xfailmsg=BUG_PARONEARG
		failmsg=even\ with\ $xfailmsg
		eq $# 1 && identic "$1" "abcdef ghijkl" && return 2 || return 1
	fi
	eq $# 3 && identic "$1|$2|$3" "abc|def ghi|jkl"
}

doTest9() {
	title='$@ concatenated, IFS is space'
	set "abc" "def ghi" "jkl"
	IFS=' '
	set xx$@yy
	IFS=
	if thisshellhas BUG_PP_06; then
		xfailmsg=BUG_PP_06
		failmsg=even\ with\ $xfailmsg
		eq $# 3 && identic "$1|$2|$3" "xxabc|def ghi|jklyy" && return 2 || return 1
	fi
	eq $# 4 && identic "$1|$2|$3|$4" "xxabc|def|ghi|jklyy"
}

doTest10() {
	title='"$@" concatenated, IFS set/empty'
	set "abc" "def ghi" "jkl"
	set "xx$@yy"
	eq $# 3 && identic "$1|$2|$3" "xxabc|def ghi|jklyy"
}

doTest11() {
	title='$@$@, IFS is space'
	set "abc" "def ghi" "jkl"
	IFS=' '
	set $@$@
	IFS=
	if thisshellhas BUG_PP_06; then
		xfailmsg=BUG_PP_06
		failmsg=even\ with\ $xfailmsg
		eq $# 5 && identic "$1|$2|$3|$4|$5" "abc|def ghi|jklabc|def ghi|jkl" && return 2 || return 1
	fi
	eq $# 7 && identic "$1|$2|$3|$4|$5|$6|$7" "abc|def|ghi|jklabc|def|ghi|jkl"
}

doTest12() {
	title='"$@$@", IFS set/empty'
	set "abc" "def ghi" "jkl"
	set "$@$@"
	eq $# 5 && identic "$1|$2|$3|$4|$5" "abc|def ghi|jklabc|def ghi|jkl"
}

# ... IFS=":" ...

doTest13() {
	title='"$*", IFS is ":"'
	set "abc" "def ghi" "jkl"
	IFS=':'
	set "$*"
	IFS=
	eq $# 1 && identic "$1" "abc:def ghi:jkl"
}

doTest14() {
	title='var=$*, IFS is ":"'
	set "abc" "def ghi" "jkl"
	IFS=':'
	var=$*
	IFS=
	identic "$var" "abc:def ghi:jkl"
}

doTest15() {
	title='var="$*", IFS is ":"'
	set "abc" "def ghi" "jkl"
	IFS=':'
	var="$*"
	IFS=
	identic "$var" "abc:def ghi:jkl"
}

doTest16() {
	title='${var-$*}, IFS is ":"'
	set "abc" "def ghi" "jkl"
	unset -v var
	IFS=':'
	set ${var-$*}
	IFS=
	if thisshellhas BUG_PP_09; then
		xfailmsg=BUG_PP_09
		failmsg=even\ with\ $xfailmsg
		eq $# 1 && identic "$1" "abc def ghi jkl" && return 2	# bash 2
		return 1
	fi
	eq $# 3 && identic "$1|$2|$3" "abc|def ghi|jkl"
}

doTest17() {
	title='"${var-$*}", IFS is ":"'
	set "abc" "def ghi" "jkl"
	unset -v var
	IFS=':'
	set "${var-$*}"
	IFS=
	eq $# 1 && identic "$1" "abc:def ghi:jkl"
}

doTest18() {
	title='${var-"$*"}, IFS is ":"'
	set "abc" "def ghi" "jkl"
	unset -v var
	IFS=':'
	set ${var-"$*"}
	IFS=
	eq $# 1 && identic "$1" "abc:def ghi:jkl"
}

doTest19() {
	title='${var=$*}, IFS is ":"'
	set "abc" "def ghi" "jkl"
	unset -v var
	IFS=':'
	set ${var=$*}
	IFS=
	if thisshellhas BUG_PP_04B; then
		xfailmsg=BUG_PP_04B
		failmsg=even\ with\ $xfailmsg
		eq $# 1 && identic "$1|var=$var" "abc def ghi jkl|var=abc def ghi jkl" && return 2	# bash 2
	fi
	eq $# 3 && identic "$1|$2|$3|var=$var" "abc|def ghi|jkl|var=abc:def ghi:jkl"
}

doTest20() {
	title='"${var=$*}", IFS is ":"'
	set "abc" "def ghi" "jkl"
	unset -v var
	IFS=':'
	set "${var=$*}"
	IFS=
	eq $# 1 && identic "$1|var=$var" "abc:def ghi:jkl|var=abc:def ghi:jkl"
}

# ... IFS='' ...

doTest21() {
	title='var="$*", IFS set/empty'
	set "abc" "def ghi" "jkl"
	IFS=
	var="$*"
	identic "$var" "abcdef ghijkl"
}

doTest22() {
	title='${var-$*}, IFS set/empty'
	set "abc" "def ghi" "jkl"
	unset -v var
	IFS=
	set ${var-$*}
	if thisshellhas BUG_PP_08; then
		xfailmsg=BUG_PP_08
		failmsg=even\ with\ $xfailmsg
		eq $# 1 && identic "$1" "abcdef ghijkl" && return 2	# bash
		eq $# 1 && identic "$1" "abc def ghi jkl" && return 2	# pdksh; bosh
		return 1
	fi
	eq $# 3 && identic "$1|$2|$3" "abc|def ghi|jkl"
}

doTest23() {
	title='"${var-$*}", IFS set/empty'
	set "abc" "def ghi" "jkl"
	unset -v var
	IFS=
	set "${var-$*}"
	eq $# 1 && identic "$1" "abcdef ghijkl"
}

doTest24() {
	title='${var-"$*"}, IFS set/empty'
	set "abc" "def ghi" "jkl"
	unset -v var
	IFS=
	set ${var-"$*"}
	eq $# 1 && identic "$1" "abcdef ghijkl"
}

doTest25() {
	title='${var=$*}, IFS set/empty'
	set "abc" "def ghi" "jkl"
	unset -v var
	IFS=
	set ${var=$*}
	if thisshellhas BUG_PP_04 && eq $# 3 && identic "$1|$2|$3|var=$var" "abc|def ghi|jkl|var=jkl"; then
		xfailmsg=BUG_PP_04
		return 2	# pdksh/mksh
	elif thisshellhas BUG_PP_04B && eq $# 3 && identic "$1|$2|$3|var=$var" "abc|def ghi|jkl|var=abc def ghi jkl"; then
		xfailmsg=BUG_PP_04B
		return 2	# bash 2.05b
	elif thisshellhas BUG_PP_04_S && eq $# 2 && identic "$1|$2|var=$var" "abcdef|ghijkl|var=abcdef ghijkl"; then
		xfailmsg=BUG_PP_04_S
		return 2	# bash 4.2, 4.3
	elif eq $# 1 && identic "$1|var=$var" "abcdef ghijkl|var=abcdef ghijkl"; then
		return 0	# no shell bug
	else
		thisshellhas BUG_PP_04 && failmsg=${failmsg-even with}\ BUG_PP_04
		thisshellhas BUG_PP_04_S && failmsg=${failmsg-even with}\ BUG_PP_04_S
		return 1	# unknown shell bug
	fi
}

doTest26() {
	title='"${var=$*}", IFS set/empty'
	set "abc" "def ghi" "jkl"
	unset -v var
	IFS=
	set "${var=$*}"
	eq $# 1 && identic "$1|var=$var" "abcdef ghijkl|var=abcdef ghijkl"
}

# ... IFS unset ...

doTest27() {
	title='"$*", IFS unset'
	set "abc" "def ghi" "jkl"
	unset -v IFS
	set "$*"
	IFS=
	eq $# 1 && identic "$1" "abc def ghi jkl"
}

doTest28() {
	title='var=$*, IFS unset'
	set "abc" "def ghi" "jkl"
	unset -v IFS
	var=$*
	IFS=
	if thisshellhas BUG_PP_03; then
		xfailmsg=BUG_PP_03
		failmsg=even\ with\ $xfailmsg
		identic "$var" "abc" && return 2	# zsh
	fi
	identic "$var" "abc def ghi jkl"
}

doTest29() {
	title='var="$*", IFS unset'
	set "abc" "def ghi" "jkl"
	unset -v IFS
	var="$*"
	IFS=
	identic "$var" "abc def ghi jkl"
}

doTest30() {
	title='${var-$*}, IFS unset'
	set "abc" "def ghi" "jkl"
	unset -v var
	unset -v IFS
	set ${var-$*}
	IFS=
	if thisshellhas BUG_PP_07; then
		# zsh
		xfailmsg=BUG_PP_07
		failmsg=even\ with\ $xfailmsg
		eq $# 3 && identic "$1|$2|$3" "abc|def ghi|jkl" && return 2 || return 1
	fi
	eq $# 4 && identic "$1|$2|$3|$4" "abc|def|ghi|jkl"
}

doTest31() {
	title='"${var-$*}", IFS unset'
	set "abc" "def ghi" "jkl"
	unset -v var
	unset -v IFS
	set "${var-$*}"
	IFS=
	eq $# 1 && identic "$1" "abc def ghi jkl"
}

doTest32() {
	title='${var-"$*"}, IFS unset'
	set "abc" "def ghi" "jkl"
	unset -v var
	unset -v IFS
	set ${var-"$*"}
	IFS=
	eq $# 1 && identic "$1" "abc def ghi jkl"
}

doTest33() {
	title='${var=$*}, IFS unset'
	set "abc" "def ghi" "jkl"
	unset -v var
	unset -v IFS
	set ${var=$*}
	IFS=
	eq $# 4 && identic "$1|$2|$3|$4|var=$var" "abc|def|ghi|jkl|var=abc def ghi jkl"
}

doTest34() {
	title='"${var=$*}", IFS unset'
	set "abc" "def ghi" "jkl"
	unset -v var
	unset -v IFS
	set "${var=$*}"
	IFS=
	eq $# 1 && identic "$1|var=$var" "abc def ghi jkl|var=abc def ghi jkl"
}

doTest35() {
	title='"$@", IFS unset'
	set "abc" "def ghi" "jkl"
	unset -v IFS
	set "$@"
	IFS=
	eq $# 3 && identic "$1|$2|$3" "abc|def ghi|jkl"
}

# ...empty fields...

doTest36() {
	title='$* with empty field, IFS unset'
	set "one" "" "three"
	unset -v IFS
	set $*
	IFS=
	if thisshellhas QRK_EMPTPPFLD; then
		okmsg=QRK_EMPTPPFLD
		failmsg=even\ with\ $okmsg
		eq $# 3 && identic "$1|$2|$3" "one||three" && return 0 || return 1
	fi
	eq $# 2 && identic "$1|$2" "one|three"
}

doTest37() {
	title='$@ with empty field, IFS unset'
	set "one" "" "three"
	unset -v IFS
	set $@
	IFS=
	if thisshellhas QRK_EMPTPPFLD; then
		okmsg=QRK_EMPTPPFLD
		failmsg=even\ with\ $okmsg
		eq $# 3 && identic "$1|$2|$3" "one||three" && return 0 || return 1
	fi
	eq $# 2 && identic "$1|$2" "one|three"
}

# ...concatenating empty PPs...

doTest38() {
	title='empty "$*", IFS set/empty'
	set --
	IFS=
	set foo "$*"
	eq $# 2 && identic "$1|$2" "foo|"
}

doTest39() {
	title='empty "${novar-}$*$(:)", IFS set/empty'
	set --
	unset -v novar
	IFS=
	set foo "${novar-}$*$(:)"
	eq $# 2 && identic "$1|$2" "foo|"
}

doTest40() {
	title='empty $@, IFS set/empty'
	set --
	IFS=
	set foo $@
	if thisshellhas BUG_PP_05; then
		# dash (at least v0.5.9.1)
		xfailmsg=BUG_PP_05
		failmsg=even\ with\ $xfailmsg
		eq $# 2 && identic "$1|$2" "foo|" && return 2 || return 1
	fi
	eq $# 1
}

doTest41() {
	title='empty "$@", IFS set/empty'
	set --
	IFS=
	set foo "$@"
	eq $# 1
}

doTest42() {
	title="empty ''\$@, IFS set/empty"
	set --
	IFS=
	set foo ''$@
	if thisshellhas BUG_PP_02; then
		xfailmsg=BUG_PP_02
		failmsg=even\ with\ $xfailmsg
		eq $# 1 && return 2 || return 1
	fi
	eq $# 2 && identic "$1|$2" "foo|"
}

doTest43() {
	title="empty ''\"\$@\", IFS set/empty"
	set --
	IFS=
	set foo ''"$@"
	if thisshellhas BUG_PP_01; then
		xfailmsg=BUG_PP_01
		failmsg=even\ with\ $xfailmsg
		eq $# 1 && return 2 || return 1
	fi
	eq $# 2 && identic "$1|$2" "foo|"
}

doTest44() {
	title='empty "${novar-}$@$(:)", IFS set/empty'
	set --
	unset -v novar
	IFS=
	set foo "${novar-}$@$(:)"
	if thisshellhas QRK_EMPTPPWRD; then
		okmsg=QRK_EMPTPPWRD
		failmsg=even\ with\ $okmsg
		eq $# 1 && return 0 || return 1
	fi
	eq $# 2 && identic "$1|$2" "foo|"
}

doTest45() {
	title='empty '\'\''"${novar-}$@$(:)", IFS set/empty'
	set --
	unset -v novar
	IFS=
	set foo ''"${novar-}$@$(:)"
	if thisshellhas BUG_PP_01; then
		xfailmsg=BUG_PP_01
		failmsg=even\ with\ $xfailmsg
		eq $# 1 && return 2 || return 1
	fi
	eq $# 2 && identic "$1|$2" "foo|"
}

lastTest=45
