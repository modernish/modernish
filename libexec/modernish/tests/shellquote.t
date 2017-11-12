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
	# regression test for BUG_BRACQUOT
	case foo in
	( f['n-p']o | f["!"@]o )
		if thisshellhas BUG_BRACQUOT; then
			xfailmsg=BUG_BRACQUOT
			return 2
		else
			failmsg='BUG_BRACQUOT not detected'
			return 1
		fi ;;
	( f[n-p]o )
		return 0 ;;
	( * )	failmsg='unknown bug'
		return 1 ;;
	esac
}

doTest3() {
	title='C-style quoting in command substitution'
	# regression test for CESCQUOT and BUG_DOLRCSUB
	foo=$(printf '{%s}' $'bar' $$'bar' $$$'bar' $$$$'bar')
	case $foo in
	( {\$bar}{${$}bar}{${$}\$bar}{${$}${$}bar} )
		if thisshellhas BUG_DOLRCSUB; then
			failmsg='BUG_DOLRCSUB wrongly detected'
			return 1
		elif thisshellhas CESCQUOT; then
			failmsg='CESCQUOT wrongly detected'
			return 1
		else
			okmsg='no CESCQUOT'
			return 0
		fi ;;
	( {bar}{${$}bar}{${$}bar}{${$}${$}bar} )
		if thisshellhas BUG_DOLRCSUB; then
			failmsg='BUG_DOLRCSUB wrongly detected'
			return 1
		elif not thisshellhas CESCQUOT; then
			failmsg='CESCQUOT not detected'
			return 1
		else
			return 0
		fi ;;
	( {bar}{bar}{${$}bar}{${$}bar} )
		if not thisshellhas BUG_DOLRCSUB; then
			failmsg='BUG_DOLRCSUB not detected'
			return 1
		elif not thisshellhas CESCQUOT; then
			failmsg='CESCQUOT not detected'
			return 1
		else
			xfailmsg=BUG_DOLRCSUB
			return 2
		fi
	esac
	failmsg='unknown bug'
	return 1
}

lastTest=3
