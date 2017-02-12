#! test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

doTest1() {
	title='isset -r: an unset readonly'
	unset -v unsetro
	readonly unsetro
	if ! isset -v unsetro && isset -r unsetro; then
		return 0
	elif thisshellhas BUG_NOUNSETRO; then
		xfailmsg=BUG_NOUNSETRO
		return 2
	else
		return 1
	fi
}

doTest2() {
	title='isset -r: a set readonly'
	readonly setro=foo
	isset -v setro && isset -r setro
}

doTest3() {
	title='isset -r: an unset non-readonly'
	unset -v unsetnonro
	! isset -v unsetnonro && ! isset -r unsetnonro
}

doTest4() {
	title='isset -r: a set non-readonly'
	setnonro=foo
	isset -v setnonro && ! isset -r setnonro
}

doTest5() {
	title='isset -x: an unset exported variable'
	unset -v unsetex
	export unsetex
	if ! isset -v unsetex && isset -x unsetex; then
		return 0
	elif thisshellhas BUG_NOUNSETEX; then
		xfailmsg=BUG_NOUNSETEX
		return 2
	else
		return 1
	fi
}

doTest6() {
	title='isset -x: a set exported variable'
	export setex=foo
	isset -v setex && isset -x setex
}

doTest7() {
	title='isset -x: an unset non-exported variable'
	unset -v unsetnonex
	! isset -v unsetnonex && ! isset -x unsetnonex
}

doTest8() {
	title='isset -x: a set non-exported variable'
	setnonex=foo
	isset -v setnonex && ! isset -x setnonex
}

doTest9() {
	title='isset -r/-x: an unset exported readonly' 
	unset -v unsetrx
	export unsetrx
	readonly unsetrx
	if ! isset -v unsetrx && isset -r unsetrx && isset -x unsetrx; then
		return 0
	elif thisshellhas BUG_NOUNSETRO || thisshellhas BUG_NOUNSETEX; then
		xfailmsg='BUG_NOUNSET{RO,EX}'
		return 2
	else
		return 1
	fi
}

doTest10() {
	title='isset -r/-x: a set exported readonly'
	export setrx=foo
	readonly setrx
	isset -v setrx && isset -r setrx && isset -x setrx
}

lastTest=10
