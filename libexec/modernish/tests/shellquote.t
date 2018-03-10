#! test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

doTest1() {
	push q quotelevel quotestring origstring
	quotelevel=8
	title="$quotelevel levels of shellquote() and back"

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
	title='shell quoting within bracket patterns'
	case foo in
	( f['n-p']o | f["!"@]o )
		mustHave BUG_BRACQUOT ;;
	( f[n-p]o )
		mustNotHave BUG_BRACQUOT ;;
	( * )	return 1 ;;
	esac
}

doTest3() {
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

lastTest=3
