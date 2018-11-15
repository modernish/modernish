#! test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# Regression tests related to modernish shellquote() and the shell's quoting mechanisms.

doTest1() {
	push q quotelevel quotestring origstring
	runExpensive && quotelevel=12 || quotelevel=3
	title="$quotelevel levels of shellquote and back"

	origstring="hi there,
	let's check	hôw this prógram
	handles 'quoting' of weird multi#line *strings*."
	quotestring=$origstring
	e=0

	q=0
	while le q+=1 quotelevel; do
		shellquote quotestring
	done

	while gt q-=1 0; do
		eval quotestring=$quotestring || { e=1; break; }
	done

	identic $quotestring $origstring || e=1
	pop q quotelevel quotestring origstring
	return $e
}

doTest2() {
	push q quotelevel quotestring origstring
	runExpensive && quotelevel=9 || quotelevel=3
	title="$quotelevel levels of shellquote -f and back"

	origstring="hi there,
	let's check	hôw this prógram
	handles 'quoting' of weird multi#line *strings*."
	quotestring=$origstring
	e=0

	q=0
	while le q+=1 quotelevel; do
		shellquote -f quotestring
	done

	while gt q-=1 0; do
		eval quotestring=$quotestring || { e=1; break; }
	done

	identic $quotestring $origstring || e=1
	pop q quotelevel quotestring origstring
	return $e
}

doTest3() {
	title='shell quoting within bracket patterns'
	case foo in
	( f['n-p']o | f["!"@]o )
		mustHave BUG_BRACQUOT ;;
	( f[n-p]o )
		mustNotHave BUG_BRACQUOT ;;
	( * )	return 1 ;;
	esac
}

doTest4() {
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

doTest5() {
	title='quotes within $(command substitutions)'
	v=$(
		eval 'put $(put "a")'
		eval "put \$(put 'b' # '$CCn)" 2>/dev/null
	)
	case $v in
	( a )	mustHave BUG_CSCMTQUOT ;;
	( ab )	mustNotHave BUG_CSCMTQUOT ;;
	( * )	return 1 ;;
	esac
}

lastTest=5
