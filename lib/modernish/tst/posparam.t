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

# bug patterns for some bash bugs with control characters...
CTRLs=$CC01$CC02$CC03$CC7F  # no bug
CTRLs_BUG_PP_10=$CC02$CC03
CTRLs_BUG_PP_10A=$CC01$CC01$CC02$CC03$CC01$CC7F
CTRLs_BUG_PSUBASNCC_unquoted=$CC02$CC03
CTRLs_BUG_PSUBASNCC_quoted=$CC02$CC03$CC7F

TEST title='$*, IFS is space'
	set "abc" "def ghi" "$CTRLs"
	IFS=' '
	set $*
	IFS=
	eq $# 4 && str eq "$1|$2|$3|$4" "abc|def|ghi|$CTRLs"
ENDT

TEST title='"$*", IFS is space'
	set "abc" "def ghi" "$CTRLs"
	IFS=' '
	set "$*"
	IFS=
	eq $# 1 && str eq "$1" "abc def ghi $CTRLs"
ENDT

TEST title='$* concatenated, IFS is space'
	set "abc" "def ghi" "$CTRLs"
	IFS=' '
	set xx$*yy
	IFS=
	eq $# 4 && str eq "$1|$2|$3|$4" "xxabc|def|ghi|${CTRLs}yy"
ENDT

TEST title='"$*" concatenated, IFS is space'
	set "abc" "def ghi" "$CTRLs"
	IFS=' '
	set "xx$*yy"
	IFS=
	eq $# 1 && str eq "$1" "xxabc def ghi ${CTRLs}yy"
ENDT

TEST title='$@, IFS is space'
	set "abc" "def ghi" "$CTRLs"
	IFS=' '
	set $@
	IFS=
	case ${#},${1-},${2-},${3-},${4-NONE} in
	( "4,abc,def,ghi,$CTRLs" )
		mustNotHave BUG_PP_06 ;;
	( "3,abc,def ghi,$CTRLs,NONE" )
		mustHave BUG_PP_06 ;;
	( * )	return 1 ;;
	esac
ENDT

TEST title='$@, IFS set/empty'
	set "abc" "def ghi" "$CTRLs"
	IFS=
	set $@
	case ${#},${1-},${2-NONE},${3-NONE} in
	( "3,abc,def ghi,$CTRLs" )
		mustNotHave BUG_PP_08 ;;
	( "1,abcdef ghi$CTRLs,NONE,NONE" )
		mustHave BUG_PP_08 ;;
	( * )	return 1 ;;
	esac
ENDT

TEST title='"$@", IFS set/empty'
	set "abc" "def ghi" "$CTRLs"
	IFS=
	set "$@"
	eq $# 3 && str eq "$1|$2|$3" "abc|def ghi|$CTRLs"
ENDT

TEST title='${1+"$@"}, IFS set/empty'
	set "abc" "def ghi" "$CTRLs"
	IFS=
	set ${1+"$@"}
	failmsg="$#|${1-}|${2-}|${3-}"
	case ${#},${1-},${2-NONE},${3-NONE} in
	( "3,abc,def ghi,$CTRLs")
		mustNotHave BUG_PP_1ARG ;;
	( "1,abcdef ghi$CTRLs,NONE,NONE" )
		mustHave BUG_PP_1ARG ;;
	( * )	return 1 ;;
	esac
ENDT


TEST title='"${1+$@}", IFS set/empty'
	set "abc" "def ghi" "$CTRLs"
	IFS=
	set "${1+$@}"
	failmsg="$#|${1-}|${2-}|${3-}"
	case ${#},${1-},${2-NONE},${3-NONE} in
	( "3,abc,def ghi,$CTRLs" )
		mustNotHave BUG_PP_1ARG ;;
	( "1,abcdef ghi$CTRLs,NONE,NONE" )
		mustHave BUG_PP_1ARG ;;
	( * )	return 1 ;;
	esac
ENDT

TEST title='${novar-"$@"}, IFS set/empty'
	set "abc" "def ghi" "$CTRLs"
	unset -v novar
	IFS=
	set ${novar-"$@"}
	case ${#},${1-},${2-NONE},${3-NONE} in
	( "3,abc,def ghi,$CTRLs")
		mustNotHave BUG_PP_1ARG ;;
	( "1,abcdef ghi$CTRLs,NONE,NONE" )
		mustHave BUG_PP_1ARG ;;
	( * )	return 1 ;;
	esac
ENDT

TEST title='$@ concatenated, IFS is space'
	set "abc" "def ghi" "$CTRLs"
	IFS=' '
	set xx$@yy
	IFS=
	case ${#},${1-},${2-},${3-},${4-NONE} in
	( "4,xxabc,def,ghi,${CTRLs}yy" )
		mustNotHave BUG_PP_06 ;;
	( "3,xxabc,def ghi,${CTRLs}yy,NONE" )
		mustHave BUG_PP_06 ;;
	( * )	return 1 ;;
	esac
ENDT

TEST title='"$@" concatenated, IFS set/empty'
	set "abc" "def ghi" "$CTRLs"
	set "xx$@yy"
	eq $# 3 && str eq "$1|$2|$3" "xxabc|def ghi|${CTRLs}yy"
ENDT

TEST title='$@$@, IFS is space'
	set "abc" "def ghi" "$CTRLs"
	IFS=' '
	set $@$@
	IFS=
	case ${#},${1-},${2-},${3-},${4-},${5-},${6-NONE},${7-NONE} in
	( "7,abc,def,ghi,${CTRLs}abc,def,ghi,$CTRLs" )
		mustNotHave BUG_PP_06 ;;
	( "5,abc,def ghi,${CTRLs}abc,def ghi,$CTRLs,NONE,NONE" )
		mustHave BUG_PP_06 ;;
	( * )	return 1 ;;
	esac
ENDT

TEST title='"$@$@", IFS set/empty'
	set "abc" "def ghi" "$CTRLs"
	set "$@$@"
	eq $# 5 && str eq "$1|$2|$3|$4|$5" "abc|def ghi|${CTRLs}abc|def ghi|$CTRLs"
ENDT

# ... IFS=":" ...

TEST title='"$*", IFS is ":"'
	set "abc" "def ghi" "$CTRLs"
	IFS=':'
	set "$*"
	IFS=
	eq $# 1 && str eq "$1" "abc:def ghi:$CTRLs"
ENDT

TEST title='var=$*, IFS is ":"'
	set "abc" "def ghi" "jkl"
	IFS=':'
	var=$*
	IFS=
	str eq "$var" "abc:def ghi:jkl" || return

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
ENDT

TEST title='var="$*", IFS is ":"'
	set "abc" "def ghi" "$CTRLs"
	IFS=':'
	var="$*"
	IFS=
	str eq "$var" "abc:def ghi:$CTRLs"
ENDT

TEST title='${var-$*}, IFS is ":"'
	set "abc" "def ghi" "$CTRLs"
	unset -v var
	IFS=':'
	set ${var-$*}
	IFS=
	case ${#},${1-},${2-NONE},${3-NONE} in
	( "3,abc,def ghi,$CTRLs" )
		mustNotHave BUG_PP_09 ;;
	( "1,abc def ghi $CTRLs,NONE,NONE" )
		mustHave BUG_PP_09 ;;	# bash 4.3
	( * )	return 1 ;;
	esac
ENDT

TEST title='"${var-$*}", IFS is ":"'
	set "abc" "def ghi" "$CTRLs"
	unset -v var
	IFS=':'
	set "${var-$*}"
	IFS=
	eq $# 1 && str eq "$1" "abc:def ghi:$CTRLs"
ENDT

TEST title='${var-"$*"}, IFS is ":"'
	set "abc" "def ghi" "$CTRLs"
	unset -v var
	IFS=':'
	set ${var-"$*"}
	IFS=
	eq $# 1 && str eq "$1" "abc:def ghi:$CTRLs"
ENDT

TEST title='${var=$*}, IFS is ":"'
	set "abc" "def ghi" "$CTRLs"
	unset -v var
	IFS=':'
	set ${var=$*}
	IFS=
	case ${#},${1-},${2-NONE},${3-NONE},var=$var in
	( "3,abc,def ghi,$CTRLs,var=abc:def ghi:$CTRLs" )
		mustNotHave BUG_PP_04E && mustNotHave BUG_PSUBASNCC ;;
	( "3,abc,def ghi,$CTRLs_BUG_PSUBASNCC_unquoted,var=abc:def ghi:$CTRLs" )
		mustNotHave BUG_PP_04E && mustHave BUG_PSUBASNCC ;;	# bash 4.2, 4.4
	( "1,abc def ghi $CTRLs_BUG_PSUBASNCC_unquoted,NONE,NONE,var=abc def ghi $CTRLs" )
		mustHave BUG_PP_04E
		eq $? 2 && mustHave BUG_PSUBASNCC ;;			# bash 4.3
	( * )	return 1 ;;
	esac
ENDT

TEST title='"${var=$*}", IFS is ":"'
	set "abc" "def ghi" "$CTRLs"
	unset -v var
	IFS=':'
	set "${var=$*}"
	IFS=
	case ${#},$1\|var=$var in
	( "1,abc:def ghi:$CTRLs|var=abc:def ghi:$CTRLs" )
		mustNotHave BUG_PSUBASNCC ;;
	( "3,abc:def ghi:$CTRLs_BUG_PSUBASNCC_quoted|var=abc:def ghi:$CTRLs" )
		mustHave BUG_PSUBASNCC ;;
	esac
ENDT

# ... IFS='' ...

TEST title='var=$*, IFS set/empty'
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
ENDT

TEST title='var="$*", IFS set/empty'
	set "abc" "$ASCIICHARS" "def ghi" "$ASCIICHARS" "jkl"
	IFS=
	var="$*"
	str eq "$var" "abc${ASCIICHARS}def ghi${ASCIICHARS}jkl"
ENDT

TEST title='${var-$*}, IFS set/empty'
	set "abc" "def ghi" "$CTRLs"
	unset -v var
	IFS=
	set ${var-$*}
	case ${#},${1-},${2-NONE},${3-NONE} in
	( "3,abc,def ghi,$CTRLs" )
		mustNotHave BUG_PP_08B && mustNotHave BUG_PSUBEMIFS ;;
	( "1,abcdef ghi$CC02$CC03,NONE,NONE" )
		mustHave BUG_PP_08B					# bash 4.4
		eq $? 2 && mustHave BUG_PSUBEMIFS ;;
	( "1,abcdef ghi$CTRLs,NONE,NONE" | "1,abc def ghi $CTRLs,NONE,NONE" )
		mustNotHave BUG_PSUBEMIFS && mustHave BUG_PP_08B ;;	# bash | pdksh/bosh
	( * )	return 1 ;;
	esac
ENDT

TEST title='"${var-$*}", IFS set/empty'
	set "abc" "def ghi" "$CTRLs"
	unset -v var
	IFS=
	set "${var-$*}"
	eq $# 1 && str eq "$1" "abcdef ghi$CTRLs"
ENDT

TEST title='${var-"$*"}, IFS set/empty'
	set "abc" "def ghi" "$CTRLs"
	unset -v var
	IFS=
	set ${var-"$*"}
	eq $# 1 && str eq "$1" "abcdef ghi$CTRLs"
ENDT

TEST title='${var=$*}, IFS set/empty'
	set "abc" "def ghi" "$CTRLs"
	unset -v var
	IFS=
	set ${var=$*}
	case ${#},${1-},${2-NONE},${3-NONE},var=$var in
	( "1,abcdef ghi$CTRLs,NONE,NONE,var=abcdef ghi$CTRLs" )
		mustNotHave BUG_PP_04 && mustNotHave BUG_PP_04_S && mustNotHave BUG_PSUBASNCC ;;
	( "3,abc,def ghi,$CTRLs,var=$CTRLs" )
		mustNotHave BUG_PP_04_S && mustNotHave BUG_PSUBASNCC && mustHave BUG_PP_04 ;;	# pdksh/mksh
	( "2,abcdef,ghi$CTRLs_BUG_PSUBASNCC_unquoted,NONE,var=abcdef ghi$CTRLs" )
		mustNotHave BUG_PP_04 && mustHave BUG_PP_04_S					# bash 4.2, 4.3
		eq $? 2 && mustHave BUG_PSUBASNCC ;;
	( "1,abcdef ghi$CTRLs_BUG_PSUBASNCC_unquoted,NONE,NONE,var=abcdef ghi$CTRLs_BUG_PSUBASNCC_quoted" )
		mustNotHave BUG_PP_04 && mustNotHave BUG_PP_04_S && mustHave BUG_PSUBASNCC ;;	# bash 4.4
	( * )	put "${#},${1-},${2-NONE},${3-NONE},var=$var" | extern -p hexdump -C >&2
		return 1 ;;
	esac
ENDT

TEST title='"${var=$*}", IFS set/empty'
	set "abc" "def ghi" "$CTRLs"
	unset -v var
	IFS=
	set "${var=$*}"
	case $#,$1\|var=$var in
	( "1,abcdef ghi$CTRLs|var=abcdef ghi$CTRLs" )
		mustNotHave BUG_PSUBASNCC ;;
	( "1,abcdef ghi$CTRLs_BUG_PSUBASNCC_quoted|var=abcdef ghi$CTRLs" )
		mustHave BUG_PSUBASNCC ;;
	esac
ENDT

# ... IFS unset ...

TEST title='"$*", IFS unset'
	set "abc" "def ghi" "$CTRLs"
	unset -v IFS
	set "$*"
	IFS=
	eq $# 1 && str eq "$1" "abc def ghi $CTRLs"
ENDT

TEST title='var=$*, IFS unset'
	set "abc" "def ghi" "$CTRLs"
	unset -v IFS
	var=$*
	IFS=
	case $var in
	( "abc def ghi $CTRLs" )
		# *may* have BUG_PP_03 variant with set & empty IFS (mksh)
		;;
	( 'abc' )
		mustHave BUG_PP_03 ;;
	( * )	return 1 ;;
	esac
ENDT

TEST title='var="$*", IFS unset'
	set "abc" "def ghi" "$CTRLs"
	unset -v IFS
	var="$*"
	IFS=
	str eq "$var" "abc def ghi $CTRLs"
ENDT

TEST title='${var-$*}, IFS unset'
	set "abc" "def ghi" "$CTRLs"
	unset -v var
	unset -v IFS
	set ${var-$*}
	IFS=
	case ${#},${1-},${2-},${3-},${4-NONE} in
	( "4,abc,def,ghi,$CTRLs" )
		mustNotHave BUG_PP_07 ;;
	( "3,abc,def ghi,$CTRLs,NONE" )
		mustHave BUG_PP_07 ;;	# zsh
	( * )	return 1 ;;
	esac
ENDT

TEST title='"${var-$*}", IFS unset'
	set "abc" "def ghi" "$CTRLs"
	unset -v var
	unset -v IFS
	set "${var-$*}"
	IFS=
	eq $# 1 && str eq "$1" "abc def ghi $CTRLs"
ENDT

TEST title='${var-"$*"}, IFS unset'
	set "abc" "def ghi" "$CTRLs"
	unset -v var
	unset -v IFS
	set ${var-"$*"}
	IFS=
	eq $# 1 && str eq "$1" "abc def ghi $CTRLs"
ENDT

TEST title='${var=$*}, IFS unset'
	set "abc" "def ghi" "$CTRLs"
	unset -v var
	unset -v IFS
	set ${var=$*}
	IFS=
	case $#,$1\|$2\|$3\|$4\|var=$var in
	( "4,abc|def|ghi|$CTRLs|var=abc def ghi $CTRLs" )
		mustNotHave BUG_PSUBASNCC ;;
	( "4,abc|def|ghi|$CTRLs_BUG_PSUBASNCC_unquoted|var=abc def ghi $CTRLs" )
		mustHave BUG_PSUBASNCC ;;
	esac
ENDT

TEST title='"${var=$*}", IFS unset'
	set "abc" "def ghi" "$CTRLs"
	unset -v var
	unset -v IFS
	set "${var=$*}"
	IFS=
	case $#,$1\|var=$var in
	( "1,abc def ghi $CTRLs|var=abc def ghi $CTRLs" )
		mustNotHave BUG_PSUBASNCC ;;
	( "1,abc def ghi $CTRLs_BUG_PSUBASNCC_quoted|var=abc def ghi $CTRLs" )
		mustHave BUG_PSUBASNCC ;;
	esac
ENDT

TEST title='"$@", IFS unset'
	set "abc" "def ghi" "$CTRLs"
	unset -v IFS
	set "$@"
	IFS=
	eq $# 3 && str eq "$1|$2|$3" "abc|def ghi|$CTRLs"
ENDT

# ...empty fields...

TEST title='$* with empty field, IFS unset'
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
ENDT

TEST title='$@ with empty field, IFS unset'
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
ENDT

# ...concatenating empty PPs...

TEST title='empty "$*", IFS set/empty'
	set --
	IFS=
	set foo "$*"
	eq $# 2 && str eq "$1|$2" "foo|"
ENDT

TEST title='empty "${novar-}$*$(:)", IFS set/empty'
	set --
	unset -v novar
	IFS=
	set foo "${novar-}$*$(:)"
	eq $# 2 && str eq "$1|$2" "foo|"
ENDT

TEST title='empty $@ and $*, IFS set/empty'
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
ENDT

TEST title='empty "$@", IFS set/empty'
	set --
	IFS=
	set foo "$@"
	eq $# 1
ENDT

TEST title="empty ''\$@, IFS set/empty"
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
ENDT

TEST title="empty ''\"\$@\", IFS set/empty"
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
ENDT

TEST title='empty "${novar-}$@$(:)", IFS set/empty'
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
ENDT

TEST title='empty '\'\''"${novar-}$@$(:)", IFS set/empty'
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
ENDT

# ... shell grammar parsing ...

TEST title='correct parsing of $#'
	set 1 2 3
	foo=$$
	case $#$foo,$(($#-1+1)) in
	( "3$foo,3" )
		;;
	( "${#foo}foo,${#-}2" | "${#foo}foo,2" )
		failmsg=FTL_HASHVAR; return 1 ;;
	( * )	return 1 ;;
	esac
ENDT

TEST title='quoting $* quotes IFS wildcards (1)'
	IFS=*	# on bash < 4.4, BUG_IFSGLOBC now breaks 'case' and hence all of modernish
	set "abc" "def ghi" "$CTRLs"
	case abcFOOBARdef\ ghiBAZQUX$CTRLs in
	("$*")	IFS=; mustHave BUG_IFSGLOBS; return ;;	# ksh93
	( * )	IFS=; mustNotHave BUG_IFSGLOBS; return ;;
	esac
	# if not even '*' matched, we've got BUG_IFSGLOBC
	IFS=	# unbreak modernish on bash < 4.4
	mustNotHave BUG_IFSGLOBS && mustHave BUG_IFSGLOBC
ENDT

TEST title='quoting $* quotes IFS wildcards (2)'
	IFS=*	# on bash < 4.4, BUG_IFSGLOBC now breaks 'case' and hence all of modernish
	set "abc" "def ghi" "$CTRLs"
	v=abcFOOBARdef\ ghiBAZQUX${CTRLs}BUG
	v=${v#"$*"}
	IFS=	# unbreak modernish on bash < 4.4
	case $v in
	( BUG )	mustHave BUG_IFSGLOBS; return ;;
	( abcFOOBARdef\ ghiBAZQUX${CTRLs}BUG )
		mustNotHave BUG_IFSGLOBS; return ;;
	esac
	return 1
ENDT

TEST title='quoted "$@" expansion is indep. of IFS'
	set "abc" "def ghi" "jkl"
	IFS=$CC01
	set "$@"
	IFS=,
	v="$*"
	IFS=
	if eq $# 1 && str eq $v "abc${CC01}def ghi${CC01}jkl"; then
		mustHave BUG_IFSCC01PP	# bash <= 3.2
	elif eq $# 27 && str eq $v ",,a,,b,,c${CC7F},,d,,e,,f,, ,,g,,h,,i${CC7F},,j,,k,,l"; then
		mustHave BUG_IFSCC01PP	# bash 4.0 - 4.3
	else
		eq $# 3 && str eq $v "abc,def ghi,jkl"
	fi
ENDT

TEST title='empty removal of unqoted nonexistent PPs'
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
ENDT

TEST title='multi-digit PPs require expansion braces'
	set one 2 3 4 5 6 7 8 9 10 11 twelve
	v=$12
	case $v in
	( 'one2' )
		mustNotHave BUG_PP_MDIGIT ;;
	( 'twelve' )
		mustHave BUG_PP_MDIGIT ;;
	( * )	return 1 ;;
	esac
ENDT
