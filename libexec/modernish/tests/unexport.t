#! test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

doTest1() {
	title="remove export flag from unset var"
	unset -v var
	export var
	unexport var
	if thisshellhas BUG_NOUNSETEX && isset -v var && not isset -x var; then
		xfailmsg=BUG_NOUNSETEX
		return 2
	fi
	not isset -x var && not isset -v var
}

doTest2() {
	title='remove export flag from set var'
	export var='foo'
	unexport var
	not isset -x var && identic $var 'foo'
}
	

doTest3() {
	title='assign new value while unexporting'
	export var='bar'
	unexport var='baz'
	not isset -x var && identic $var 'baz'
}

lastTest=3
