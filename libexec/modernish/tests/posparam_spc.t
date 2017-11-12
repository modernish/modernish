#! test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# These $@ and $* tests are the same as in posparam.t, but with leading and
# trailing spaces added to the test parameter values. This catches more
# corner case bugs in shells that modernish should be testing for.
#
# The tests with no PPs ($# == 0) from posparam.t are not repeated here.

doTest1() {
	title='$*, IFS is space'
	set " abc " " def ghi " " jkl "
	IFS=' '
	set $*
	IFS=
	eq $# 4 && identic "$1|$2|$3|$4" "abc|def|ghi|jkl"
}

doTest2() {
	title='$*, IFS is unset'
	set " a${CCn}b${CCt}c " " de${CCn}f g${CCt}hi${CCn}" "${CCn}j${CCt} kl${CCt}"
	unset -v IFS
	set $*
	IFS=
	if thisshellhas BUG_PP_06A; then
		xfailmsg=BUG_PP_06A
		failmsg=even\ with\ $xfailmsg
		eq $# 3 && identic "$1|$2|$3" " a${CCn}b${CCt}c | de${CCn}f g${CCt}hi${CCn}|${CCn}j${CCt} kl${CCt}" && return 2
		return 1
	elif thisshellhas BUG_PP_07A; then
		xfailmsg=BUG_PP_07A
		failmsg=even\ with\ $xfailmsg
		eq $# 5 && identic "$1|$2|$3|$4|$5" "a${CCn}b${CCt}c|de${CCn}f|g${CCt}hi${CCn}|${CCn}j${CCt}|kl${CCt}" && return 2
		return 1
	fi
	eq $# 9 && identic "$1|$2|$3|$4|$5|$6|$7|$8|$9" "a|b|c|de|f|g|hi|j|kl"
}

doTest3() {
	title='"$*", IFS is space'
	set " abc " " def ghi " " jkl "
	IFS=' '
	set "$*"
	IFS=
	eq $# 1 && identic "$1" " abc   def ghi   jkl "
}

doTest4() {
	title='$* concatenated, IFS is space'
	set " abc " " def ghi " " jkl "
	IFS=' '
	set xx$*yy
	IFS=
	eq $# 6 && identic "$1|$2|$3|$4|$5|$6" "xx|abc|def|ghi|jkl|yy"
}

doTest5() {
	title='"$*" concatenated, IFS is space'
	set " abc " " def ghi " " jkl "
	IFS=' '
	set "xx$*yy"
	IFS=
	eq $# 1 && identic "$1" "xx abc   def ghi   jkl yy"
}

doTest6() {
	title='$@, IFS is space'
	set " abc " " def ghi " " jkl "
	IFS=' '
	set $@
	IFS=
	if thisshellhas BUG_PP_06; then
		xfailmsg=BUG_PP_06
		failmsg=even\ with\ $xfailmsg
		eq $# 3 && identic "$1|$2|$3" " abc | def ghi | jkl " && return 2 || return 1
	fi
	eq $# 4 && identic "$1|$2|$3|$4" "abc|def|ghi|jkl"
}

doTest7() {
	title='"$@", IFS set/empty'
	set " abc " " def ghi " " jkl "
	IFS=
	set "$@"
	eq $# 3 && identic "$1|$2|$3" " abc | def ghi | jkl "
}

doTest8() {
	title='${1+"$@"}, IFS set/empty'
	set " abc " " def ghi " " jkl "
	IFS=
	set ${1+"$@"}
	failmsg="$#|${1-}|${2-}|${3-}"
	if thisshellhas BUG_PARONEARG; then
		xfailmsg=BUG_PARONEARG
		failmsg=even\ with\ $xfailmsg
		eq $# 1 && identic "$1" " abc  def ghi  jkl " && return 2 || return 1
	fi
	eq $# 3 && identic "$1|$2|$3" " abc | def ghi | jkl "
}

doTest9() {
	title='${novar-"$@"}, IFS set/empty'
	set " abc " " def ghi " " jkl "
	unset -v novar
	IFS=
	set ${novar-"$@"}
	failmsg="$#|${1-}|${2-}|${3-}"
	if thisshellhas BUG_PARONEARG; then
		xfailmsg=BUG_PARONEARG
		failmsg=even\ with\ $xfailmsg
		eq $# 1 && identic "$1" " abc  def ghi  jkl " && return 2 || return 1
	fi
	eq $# 3 && identic "$1|$2|$3" " abc | def ghi | jkl "
}

doTest10() {
	title='$@ concatenated, IFS is space'
	set " abc " " def ghi " " jkl "
	IFS=' '
	set xx$@yy
	IFS=
	if thisshellhas BUG_PP_06; then
		xfailmsg=BUG_PP_06
		failmsg=even\ with\ $xfailmsg
		eq $# 3 && identic "$1|$2|$3" "xx abc | def ghi | jkl yy" && return 2 || return 1
	fi
	eq $# 6 && identic "$1|$2|$3|$4|$5|$6" "xx|abc|def|ghi|jkl|yy"
}

doTest11() {
	title='"$@" concatenated, IFS set/empty'
	set " abc " " def ghi " " jkl "
	set "xx$@yy"
	eq $# 3 && identic "$1|$2|$3" "xx abc | def ghi | jkl yy"
}

doTest12() {
	title='$@$@, IFS is space'
	set " abc " " def ghi " " jkl "
	IFS=' '
	set $@$@
	IFS=
	if thisshellhas BUG_PP_06; then
		xfailmsg=BUG_PP_06
		failmsg=even\ with\ $xfailmsg
		eq $# 5 && identic "$1|$2|$3|$4|$5" " abc | def ghi | jkl  abc | def ghi | jkl " && return 2 || return 1
	fi
	eq $# 8 && identic "$1|$2|$3|$4|$5|$6|$7|$8" "abc|def|ghi|jkl|abc|def|ghi|jkl"
}

doTest13() {
	title='"$@$@", IFS set/empty'
	set " abc " " def ghi " " jkl "
	set "$@$@"
	eq $# 5 && identic "$1|$2|$3|$4|$5" " abc | def ghi | jkl  abc | def ghi | jkl "
}

# ... IFS=":" ...

doTest14() {
	title='"$*", IFS is ":"'
	set " abc " " def ghi " " jkl "
	IFS=':'
	set "$*"
	IFS=
	eq $# 1 && identic "$1" " abc : def ghi : jkl "
}

doTest15() {
	title='var=$*, IFS is ":"'
	set " abc " " def ghi " " jkl "
	IFS=':'
	var=$*
	IFS=
	identic "$var" " abc : def ghi : jkl "
}

doTest16() {
	title='var="$*", IFS is ":"'
	set " abc " " def ghi " " jkl "
	IFS=':'
	var="$*"
	IFS=
	identic "$var" " abc : def ghi : jkl "
}

doTest17() {
	title='${var-$*}, IFS is ":"'
	set " abc " " def ghi " " jkl "
	unset -v var
	IFS=':'
	set ${var-$*}
	IFS=
	if thisshellhas BUG_PP_09; then
		xfailmsg=BUG_PP_09
		failmsg=even\ with\ $xfailmsg
		eq $# 1 && identic "$1" " abc   def ghi   jkl " && return 2	# bash 2
		return 1
	fi
	eq $# 3 && identic "$1|$2|$3" " abc | def ghi | jkl "
}

doTest18() {
	title='"${var-$*}", IFS is ":"'
	set " abc " " def ghi " " jkl "
	unset -v var
	IFS=':'
	set "${var-$*}"
	IFS=
	eq $# 1 && identic "$1" " abc : def ghi : jkl "
}

doTest19() {
	title='${var-"$*"}, IFS is ":"'
	set " abc " " def ghi " " jkl "
	unset -v var
	IFS=':'
	set ${var-"$*"}
	IFS=
	eq $# 1 && identic "$1" " abc : def ghi : jkl "
}

doTest20() {
	title='${var=$*}, IFS is ":"'
	set " abc " " def ghi " " jkl "
	unset -v var
	IFS=':'
	set ${var=$*}
	IFS=
	if thisshellhas BUG_PP_04B; then
		xfailmsg=BUG_PP_04B
		failmsg=even\ with\ $xfailmsg
		eq $# 1 && identic "$1|var=$var" " abc   def ghi   jkl |var= abc   def ghi   jkl " && return 2	# bash 2
	fi
	eq $# 3 && identic "$1|$2|$3|var=$var" " abc | def ghi | jkl |var= abc : def ghi : jkl "
}

doTest21() {
	title='"${var=$*}", IFS is ":"'
	set " abc " " def ghi " " jkl "
	unset -v var
	IFS=':'
	set "${var=$*}"
	IFS=
	eq $# 1 && identic "$1|var=$var" " abc : def ghi : jkl |var= abc : def ghi : jkl "
}

# ... IFS='' ...

doTest22() {
	title='var="$*", IFS set/empty'
	set " abc " " def ghi " " jkl "
	IFS=
	var="$*"
	identic "$var" " abc  def ghi  jkl "
}

doTest23() {
	title='${var-$*}, IFS set/empty'
	set " abc " " def ghi " " jkl "
	unset -v var
	IFS=
	set ${var-$*}
	if thisshellhas BUG_PP_08B; then
		xfailmsg=BUG_PP_08B
		failmsg=even\ with\ $xfailmsg
		eq $# 1 && identic "$1" " abc  def ghi  jkl " && return 2	# bash
		eq $# 1 && identic "$1" " abc   def ghi   jkl " && return 2	# bosh
		return 1
	fi
	eq $# 3 && identic "$1|$2|$3" " abc | def ghi | jkl "
}

doTest24() {
	title='"${var-$*}", IFS set/empty'
	set " abc " " def ghi " " jkl "
	unset -v var
	IFS=
	set "${var-$*}"
	eq $# 1 && identic "$1" " abc  def ghi  jkl "
}

doTest25() {
	title='${var-"$*"}, IFS set/empty'
	set " abc " " def ghi " " jkl "
	unset -v var
	IFS=
	set ${var-"$*"}
	eq $# 1 && identic "$1" " abc  def ghi  jkl "
}

doTest26() {
	title='${var=$*}, IFS set/empty'
	set " abc " " def ghi " " jkl "
	unset -v var
	IFS=
	set ${var=$*}
	if thisshellhas BUG_PP_04 && eq $# 3 \
	&& identic "$1|$2|$3|var=$var" " abc | def ghi | jkl |var= jkl "; then
		xfailmsg=BUG_PP_04
		return 2	# pdksh/mksh
	elif thisshellhas BUG_PP_04B && eq $# 3 \
	&& identic "$1|$2|$3|var=$var" " abc | def ghi | jkl |var= abc   def ghi   jkl "; then
		xfailmsg=BUG_PP_04B
		return 2	# bash 2.05b
	elif thisshellhas BUG_PP_04_S && eq $# 4 \
	&& identic "$1|$2|$3|$4|var=$var" "abc|def|ghi|jkl|var= abc  def ghi  jkl "; then
		xfailmsg=BUG_PP_04_S
		return 2	# bash 4.2, 4.3
	elif eq $# 1 && identic "$1|var=$var" " abc  def ghi  jkl |var= abc  def ghi  jkl "; then
		return 0	# no shell bug
	else
		thisshellhas BUG_PP_04 && failmsg=${failmsg-even with}\ BUG_PP_04
		thisshellhas BUG_PP_04_S && failmsg=${failmsg-even with}\ BUG_PP_04_S
		return 1	# unknown shell bug
	fi
}

doTest27() {
	title='"${var=$*}", IFS set/empty'
	set " abc " " def ghi " " jkl "
	unset -v var
	IFS=
	set "${var=$*}"
	eq $# 1 && identic "$1|var=$var" " abc  def ghi  jkl |var= abc  def ghi  jkl "
}

# ... IFS unset ...

doTest28() {
	title='"$*", IFS unset'
	set " abc " " def ghi " " jkl "
	unset -v IFS
	set "$*"
	IFS=
	eq $# 1 && identic "$1" " abc   def ghi   jkl "
}

doTest29() {
	title='var=$*, IFS unset'
	set " abc " " def ghi " " jkl "
	unset -v IFS
	var=$*
	IFS=
	if thisshellhas BUG_PP_03; then
		xfailmsg=BUG_PP_03
		failmsg=even\ with\ $xfailmsg
		identic "$var" " abc " && return 2		# zsh
	fi
	if thisshellhas BUG_PP_03A; then
		xfailmsg=${xfailmsg+$xfailmsg, }BUG_PP_03A
		failmsg=even\ with\ $xfailmsg
		identic "$var" "abc def ghi jkl" && return 2	# bash
	fi
	identic "$var" " abc   def ghi   jkl "
}

doTest30() {
	title='var=${var-$*}, IFS unset'
	set " abc " " def ghi " " jkl "
	unset -v IFS v
	v=${v-$*}
	IFS=
	if thisshellhas BUG_PP_03B; then
		xfailmsg=BUG_PP_03B
		failmsg=even\ with\ $xfailmsg
		identic "$v" "abc def ghi jkl" && return 2	# bash 4.3, 4.4
		return 1
	elif thisshellhas BUG_PP_03C; then
		xfailmsg=BUG_PP_03C
		failmsg=even\ with\ $xfailmsg
		identic "$v" " abc " && return 2		# zsh 5.3, 5.3.1
		return 1
	fi
	identic "$v" " abc   def ghi   jkl "
}

doTest31() {
	title='var="$*", IFS unset'
	set " abc " " def ghi " " jkl "
	unset -v IFS
	var="$*"
	IFS=
	identic "$var" " abc   def ghi   jkl "
}

doTest32() {
	title='${var-$*}, IFS unset'
	set " abc " " def ghi " " jkl "
	unset -v var
	unset -v IFS
	set ${var-$*}
	IFS=
	if thisshellhas BUG_PP_07; then
		# zsh
		xfailmsg=BUG_PP_07
		failmsg=even\ with\ $xfailmsg
		eq $# 3 && identic "$1|$2|$3" " abc | def ghi | jkl " && return 2 || return 1
	fi
	eq $# 4 && identic "$1|$2|$3|$4" "abc|def|ghi|jkl"
}

doTest33() {
	title='"${var-$*}", IFS unset'
	set " abc " " def ghi " " jkl "
	unset -v var
	unset -v IFS
	set "${var-$*}"
	IFS=
	eq $# 1 && identic "$1" " abc   def ghi   jkl "
}

doTest34() {
	title='${var-"$*"}, IFS unset'
	set " abc " " def ghi " " jkl "
	unset -v var
	unset -v IFS
	set ${var-"$*"}
	IFS=
	eq $# 1 && identic "$1" " abc   def ghi   jkl "
}

doTest35() {
	title='${var=$*}, IFS unset'
	set " abc " " def ghi " " jkl "
	unset -v var
	unset -v IFS
	set ${var=$*}
	IFS=
	if thisshellhas BUG_PP_04A; then
		xfailmsg=BUG_PP_04A
		failmsg=even\ with\ $xfailmsg
		eq $# 4 && identic "$1|$2|$3|$4|var=$var" "abc|def|ghi|jkl|var=abc def ghi jkl" && return 2	# bash
	fi
	if thisshellhas BUG_PP_04C; then
		xfailmsg=BUG_PP_04C
		failmsg=even\ with\ $xfailmsg
		eq $# 5 && identic "$1|$2|$3|$4|$5|var=$var" "|abc|def|ghi|jkl|var= abc   def ghi   jkl " \
		&& return 2	# mksh R50
	fi
	eq $# 4 && identic "$1|$2|$3|$4|var=$var" "abc|def|ghi|jkl|var= abc   def ghi   jkl "
}

doTest36() {
	title='"${var=$*}", IFS unset'
	set " abc " " def ghi " " jkl "
	unset -v var
	unset -v IFS
	set "${var=$*}"
	IFS=
	eq $# 1 && identic "$1|var=$var" " abc   def ghi   jkl |var= abc   def ghi   jkl "
}

doTest37() {
	title='"$@", IFS unset'
	set " abc " " def ghi " " jkl "
	unset -v IFS
	set "$@"
	IFS=
	eq $# 3 && identic "$1|$2|$3" " abc | def ghi | jkl "
}

# ...empty fields...

doTest38() {
	title='$* with empty field, IFS unset'
	set " one " "" " three "
	unset -v IFS
	set $*
	IFS=
	if thisshellhas QRK_EMPTPPFLD; then
		okmsg=QRK_EMPTPPFLD
		failmsg=even\ with\ $okmsg
		eq $# 3 && identic "$1|$2|$3" "one||three" && return 0
	fi
	if thisshellhas BUG_PP_07; then
		xfailmsg=BUG_PP_07
		failmsg=even\ with\ $xfailmsg
		eq $# 2 && identic "$1|$2" " one | three " && return 2
	fi
	eq $# 2 && identic "$1|$2" "one|three"
}

doTest39() {
	title='$@ with empty field, IFS unset'
	set " one " "" " three "
	unset -v IFS
	set $@
	IFS=
	if thisshellhas QRK_EMPTPPFLD; then
		okmsg=QRK_EMPTPPFLD
		failmsg=even\ with\ $okmsg
		eq $# 3 && identic "$1|$2|$3" "one||three" && return 0
	fi
	if thisshellhas BUG_PP_07; then
		xfailmsg=BUG_PP_07
		failmsg=even\ with\ $xfailmsg
		eq $# 2 && identic "$1|$2" " one | three " && return 2
	fi
	eq $# 2 && identic "$1|$2" "one|three"
}

lastTest=39
