#! test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

mktemp -sCCC /tmp/is.XXXXXX
isTestFile=$REPLY

doTest1() {
	title='is older: nonexistent 1st file'
	is older /dev/null/nonexistent $MSH_SHELL
}

doTest2() {
	title='is older: nonexistent 2nd file'
	! is older $MSH_SHELL /dev/null/nonexistent
}

doTest3() {
	title='is older: both files nonexistent'
	! is older /dev/null/no1 /dev/null/no2
}

doTest4() {
	title='is older: both files exist'
	is older $MSH_SHELL $isTestFile
}

doTest5() {
	title='is newer: nonexistent 1st file'
	! is newer /dev/null/nonexistent $MSH_SHELL
}

doTest6() {
	title='is newer: nonexistent 2nd file'
	is newer $MSH_SHELL /dev/null/nonexistent
}

doTest7() {
	title='is newer: both files nonexistent'
	! is newer /dev/null/no1 /dev/null/no2
}

doTest8() {
	title='is newer: both files exist'
	is newer $isTestFile $MSH_SHELL
}

lastTest=8
