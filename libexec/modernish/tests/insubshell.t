#! test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# Test the insubshell() function that checks if we're in a subshell or not.
# This includes background job subshells.
#
# The correct functioning of insubshell() is essential for die(), harden(),
# the trap stack, and mktemp().

doTest1() {
	title='main shell'
	not insubshell
}

doTest2() {
	title='regular subshell'
	( : 1>&1; insubshell )
}

doTest3() {
	title='command substitution subshell'
	return $( : 1>&1; insubshell; put $? )
	#	  ^^^^^^ test BUG_KSHSUBVAR resistance
}

doTest4() {
	title='background job subshell'
	# modernish mktemp: [s]ilent (no output); auto-[C]leanup; store filename in $REPLY
	mktemp -sC /tmp/insubshell-test4.XXXXXX
	test4file=$REPLY
	# launch test background job
	( : 1>&1; insubshell && echo ok || echo NO ) >|$test4file &
	while not is nonempty $test4file; do
		:	# wait until background job is done
	done
	read result <$test4file
	identic $result ok
}

doTest5() {
	title='last element of pipe is subshell?'
	# This tests if insubshell() results are consistent with LEPIPEMAIN
	# feature detection results.
	: | insubshell
	e=$?
	if thisshellhas LEPIPEMAIN; then
		okmsg="it's not: LEPIPEMAIN"
		failmsg="it is, in spite of LEPIPEMAIN"
		eq e 1
	else
		okmsg="it is"
		failmsg="it's not, though no LEPIPEMAIN"
		eq e 0
	fi
}

lastTest=5
