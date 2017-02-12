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

lastTest=1
