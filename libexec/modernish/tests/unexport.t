#! test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

use var/unexport

doTest1() {
	title="remove export flag from unset var"
	unset -v var
	export var
	unexport var
	if not isset -v var && not isset -x var; then
		mustNotHave BUG_NOUNSETEX
	elif isset -v var && not isset -x var; then
		mustHave BUG_NOUNSETEX
	else
		return 1
	fi
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
