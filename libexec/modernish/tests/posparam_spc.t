#! test/for/moderni/sh
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
	case ${#},${1-},${2-},${3-},${4-NONE},${5-NONE},${6-NONE},${7-NONE},${8-NONE},${9-NONE} in
	( "9,a,b,c,de,f,g,hi,j,kl" )
		mustNotHave BUG_PP_06A && mustNotHave BUG_PP_07A ;;
	( "3, a${CCn}b${CCt}c , de${CCn}f g${CCt}hi${CCn},${CCn}j${CCt} kl${CCt},NONE,NONE,NONE,NONE,NONE,NONE" )
		mustNotHave BUG_PP_07A && mustHave BUG_PP_06A ;;
	( "5,a${CCn}b${CCt}c,de${CCn}f,g${CCt}hi${CCn},${CCn}j${CCt},kl${CCt},NONE,NONE,NONE,NONE" )
		mustNotHave BUG_PP_06A && mustHave BUG_PP_07A ;;
	( * )	return 1 ;;
	esac
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
	case ${#},${1-},${2-},${3-},${4-NONE} in
	( 4,abc,def,ghi,jkl )
		mustNotHave BUG_PP_06 ;;
	( '3, abc , def ghi , jkl ,NONE' )
		mustHave BUG_PP_06 ;;
	( * )	return 1 ;;
	esac
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
	case ${#},${1-},${2-NONE},${3-NONE} in
	( '3, abc , def ghi , jkl ')
		mustNotHave BUG_PARONEARG ;;
	( '1, abc  def ghi  jkl ,NONE,NONE' )
		mustHave BUG_PARONEARG ;;
	( * )	return 1 ;;
	esac
}

doTest9() {
	title='${novar-"$@"}, IFS set/empty'
	set " abc " " def ghi " " jkl "
	unset -v novar
	IFS=
	set ${novar-"$@"}
	case ${#},${1-},${2-NONE},${3-NONE} in
	( '3, abc , def ghi , jkl ')
		mustNotHave BUG_PARONEARG ;;
	( '1, abc  def ghi  jkl ,NONE,NONE' )
		mustHave BUG_PARONEARG ;;
	( * )	return 1 ;;
	esac
}

doTest10() {
	title='$@ concatenated, IFS is space'
	set " abc " " def ghi " " jkl "
	IFS=' '
	set xx$@yy
	IFS=
	case ${#},${1-},${2-},${3-},${4-NONE},${5-NONE},${6-NONE} in
	( '6,xx,abc,def,ghi,jkl,yy' )
		mustNotHave BUG_PP_06 ;;
	( '3,xx abc , def ghi , jkl yy,NONE,NONE,NONE' )
		mustHave BUG_PP_06 ;;
	( * )	return 1 ;;
	esac
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
	case ${#},${1-},${2-},${3-},${4-},${5-},${6-NONE},${7-NONE},${8-NONE} in
	( '8,abc,def,ghi,jkl,abc,def,ghi,jkl' )
		mustNotHave BUG_PP_06 ;;
	( '5, abc , def ghi , jkl  abc , def ghi , jkl ,NONE,NONE,NONE' )
		mustHave BUG_PP_06 ;;
	( * )	return 1 ;;
	esac
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
	case ${#},${1-},${2-NONE},${3-NONE} in
	( '3, abc , def ghi , jkl ' )
		mustNotHave BUG_PP_09 ;;
	( '1, abc   def ghi   jkl ,NONE,NONE' )
		mustHave BUG_PP_09 ;;	# bash 2
	( * )	return 1 ;;
	esac
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
	case ${#},${1-},${2-NONE},${3-NONE},var=$var in
	( '3, abc , def ghi , jkl ,var= abc : def ghi : jkl ' )
		mustNotHave BUG_PP_04B && mustNotHave BUG_PP_04E ;;
	( '1, abc   def ghi   jkl ,NONE,NONE,var= abc   def ghi   jkl ' )
		if thisshellhas BUG_PP_04B; then
			mustNotHave BUG_PP_04E || return
			xfailmsg=BUG_PP_04B	# bash 2.05b
			return 2
		elif thisshellhas BUG_PP_04E; then
			mustNotHave BUG_PP_04B || return
			xfailmsg=BUG_PP_04E	# bash 4.3.30
			return 2
		else
			failmsg='BUG_PP_04{B,E} not detected'
			return 1
		fi ;;
	( * )	return 1 ;;
	esac
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
	case ${#},${1-},${2-NONE},${3-NONE} in
	( '3, abc , def ghi , jkl ' )
		mustNotHave BUG_PP_08B ;;
	( '1, abc  def ghi  jkl ,NONE,NONE' | '1, abc   def ghi   jkl ,NONE,NONE' )
		mustHave BUG_PP_08B ;;	# bash | pdksh/bosh
	( * )	return 1 ;;
	esac
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
	case ${#},${1-},${2-NONE},${3-NONE},${4-NONE},var=$var in
	( '1, abc  def ghi  jkl ,NONE,NONE,NONE,var= abc  def ghi  jkl ' )
		mustNotHave BUG_PP_04 && mustNotHave BUG_PP_04B && mustNotHave BUG_PP_04_S ;;
	( '3, abc , def ghi , jkl ,NONE,var= jkl ' )
		mustNotHave BUG_PP_04B && mustNotHave BUG_PP_04_S && mustHave BUG_PP_04 ;;	# pdksh/mksh
	( '3, abc , def ghi , jkl ,NONE,var= abc   def ghi   jkl ' )
		mustNotHave BUG_PP_04 && mustNotHave BUG_PP_04_S && mustHave BUG_PP_04B ;;	# bash 2.05b
	( '4,abc,def,ghi,jkl,var= abc  def ghi  jkl ' )
		mustNotHave BUG_PP_04 && mustNotHave BUG_PP_04B && mustHave BUG_PP_04_S ;;	# bash 4.2, 4.3
	( * )	return 1 ;;
	esac
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
	case $var in
	( ' abc   def ghi   jkl ' )
		# *may* have BUG_PP_03 variant with set & empty IFS (mksh)
		mustNotHave BUG_PP_03A ;; 
	( 'abc def ghi jkl' )	# bash
		mustNotHave BUG_PP_03 && mustHave BUG_PP_03A ;;
	( ' abc ' )		# zsh
		mustNotHave BUG_PP_03A && mustHave BUG_PP_03 ;;
	( * )	return 1 ;;
	esac
}

doTest30() {
	title='var=${var-$*}, IFS unset'
	set " abc " " def ghi " " jkl "
	unset -v IFS v
	v=${v-$*}
	IFS=
	case $v in
	( ' abc   def ghi   jkl ' )
		mustNotHave BUG_PP_03B && mustNotHave BUG_PP_03C ;;
	( 'abc def ghi jkl' )	# bash 4.3, 4.4
		mustNotHave BUG_PP_03C && mustHave BUG_PP_03B ;;
	( ' abc ' )		# zsh 5.3, 5.3.1
		mustNotHave BUG_PP_03B && mustHave BUG_PP_03C ;;
	( * )	return 1 ;;
	esac
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
	case ${#},${1-},${2-},${3-},${4-NONE} in
	( '4,abc,def,ghi,jkl' )
		mustNotHave BUG_PP_07 ;;
	( '3, abc , def ghi , jkl ,NONE' )
		mustHave BUG_PP_07 ;;	# zsh
	( * )	return 1 ;;
	esac
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
	case ${#},${1-},${2-},${3-},${4-},${5-NONE},var=$var in
	( '4,abc,def,ghi,jkl,NONE,var= abc   def ghi   jkl ' )
		mustNotHave BUG_PP_04A && mustNotHave BUG_PP_04D ;;
	( '4,abc,def,ghi,jkl,NONE,var=abc def ghi jkl' )	# bash
		mustNotHave BUG_PP_04D && mustHave BUG_PP_04A ;;
	( '5,,abc,def,ghi,jkl,var= abc   def ghi   jkl ' )	# mksh <= R50
		mustNotHave BUG_PP_04A && mustHave BUG_PP_04D ;;
	( * )	return 1 ;;
	esac
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
	case ${#},${1-},${2-},${3-NONE} in
	( '2,one,three,NONE' )
		mustNotHave BUG_PP_07 && mustNotHave QRK_EMPTPPFLD ;;
	( '3,one,,three' )
		mustNotHave BUG_PP_07 && mustHave QRK_EMPTPPFLD ;;
	( '2, one , three ,NONE' )
		mustNotHave QRK_EMPTPPFLD && mustHave BUG_PP_07 ;;
	( * )	return 1 ;;
	esac
}

doTest39() {
	title='$@ with empty field, IFS unset'
	set " one " "" " three "
	unset -v IFS
	set $@
	IFS=
	case ${#},${1-},${2-},${3-NONE} in
	( '2,one,three,NONE' )
		mustNotHave BUG_PP_07 && mustNotHave QRK_EMPTPPFLD ;;
	( '3,one,,three' )
		mustNotHave BUG_PP_07 && mustHave QRK_EMPTPPFLD ;;
	( '2, one , three ,NONE' )
		mustNotHave QRK_EMPTPPFLD && mustHave BUG_PP_07 ;;
	( * )	return 1 ;;
	esac
}

doTest40() {
	title='quoted "$@" expansion is indep. of IFS'
	set " one " "" " three "
	IFS=$CC01
	set "$@"
	IFS=,
	v="$*"
	IFS=
	if eq $# 1 && identic $v " one ${CC7F}${CC01} three "; then
		mustHave BUG_IFSCC01PP  # bash <= 3.2
	elif eq $# 25 && identic $v ",, ,,o,,n,,e,, ${CC7F}${CC7F},, ,,t,,h,,r,,e,,e,, "; then
		mustHave BUG_IFSCC01PP	# bash 4.0 - 4.3
	else
		eq $# 3 && identic $1,$2,$3 ' one ,, three '
	fi
}

lastTest=40
