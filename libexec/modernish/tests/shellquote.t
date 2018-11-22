#! test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# Regression tests related to modernish shellquote() and the shell's quoting mechanisms.

# ---- shellquote() ----

readonly \
shellquote_numstrings=4 \
shellquote_orig_string_1=$CCn \
shellquote_orig_string_2=\' \
shellquote_orig_string_3=$ASCIICHARS \
shellquote_orig_string_4="

	hi t\$here,
	let's check	h\\ôw \`this\` prógram
	handles 'quoting' of \\weird multi#line *strings*.

\\\\\\
	\\ \\  \\  

"

do_shellquote_test() {
	title="$1 levels of shellquote${2:+ $2} and back"
	setlocal e=0 i=0 lvl ostring qstring; do
		while le i+=1 shellquote_numstrings; do
			eval ostring=\${shellquote_orig_string_$i}
			qstring=$ostring
			lvl=0
			while le lvl+=1 $1; do
				shellquote ${2+$2} qstring  # BUG_PSUBEMPT compat: don't use ${2-} here
				if not contains ${2-} P && contains $qstring $CCn; then
					failmsg='non-P result w/ newline'
					return 1
				fi
			done
			while gt lvl-=1 0; do
				if not (eval qstring=$qstring); then
					failmsg="quoted string doesn't eval"
					return 1
				fi
				eval qstring=$qstring
			done
			if not identic $qstring $ostring; then
				failmsg='unquoted string not identical'
				return 1
			fi
		done
	endlocal
}

doTest1() {
	runExpensive && v=12 || v=3
	do_shellquote_test $v
}

doTest2() {
	runExpensive && v=9 || v=3
	do_shellquote_test $v -f
}

doTest3() {
	runExpensive && v=11 || v=3
	do_shellquote_test $v -P
}

doTest4() {
	runExpensive && v=8 || v=3
	do_shellquote_test $v -fP
}

# --- the shell's quoting mechanisms ----

doTest5() {
	title='shell quoting within bracket patterns'
	case foo in
	( f['n-p']o | f["!"@]o )
		mustHave BUG_BRACQUOT ;;
	( f[n-p]o )
		mustNotHave BUG_BRACQUOT ;;
	( * )	return 1 ;;
	esac
}

doTest6() {
	title='C-style quoting in command substitution'
	# regression test for CESCQUOT and BUG_DOLRCSUB
	foo=$(printf '{%s}' $'bar' $$'bar' $$$'bar' $$$$'bar')
	case $foo in
	( {\$bar}{${$}bar}{${$}\$bar}{${$}${$}bar} )
		okmsg='no CESCQUOT'
		mustNotHave CESCQUOT && mustNotHave BUG_DOLRCSUB ;;
	( {bar}{${$}bar}{${$}bar}{${$}${$}bar} )
		mustHave CESCQUOT && mustNotHave BUG_DOLRCSUB  ;;
	( {bar}{bar}{${$}bar}{${$}bar} )
		mustHave CESCQUOT && mustHave BUG_DOLRCSUB ;;
	( * )	return 1 ;;
	esac
}

doTest7() {
	title='quotes within $(command substitutions)'
	v=$(
		eval 'put $(put "a")'
		eval "put \$(put 'b' # '$CCn)" 2>/dev/null
	)
	case $v in
	( a )	failmsg=FTL_CSCMTQUOT; return 1 ;;
	( ab )	;;
	( * )	return 1 ;;
	esac
}

lastTest=7
