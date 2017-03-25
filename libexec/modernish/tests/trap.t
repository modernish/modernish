#! test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# Test the trap stack and POSIX traps.

mktemp -sC "/tmp/trap.t test 1.XXXXXX"
trap_testfile=$REPLY
trap_testfile_q=$REPLY
shellquote trap_testfile_q

doTest1() {
	title='push traps'
	push IFS -C -u
	failmsg='trap 1' \
	&& IFS=abc && set -C \
	&& pushtrap "identic \"\$IFS\" abc && isset -C && putln 'trap1ok' >>$trap_testfile_q" ALRM \
	&& failmsg='trap 2' \
	&& IFS= && set +C \
	&& pushtrap "empty \"\$IFS\" && not isset -C && putln 'trap2ok' >>$trap_testfile_q" SIGALRM \
	&& failmsg='trap 3' \
	&& unset -v IFS && set +u \
	&& pushtrap "not isset IFS && not isset -u && putln 'trap3ok' >>$trap_testfile_q" sIgAlRm
	pop --keepstatus IFS -C -u || return 1
}

doTest2() {
	title='set POSIX trap'
	trap "putln 'POSIX-trap' >>$trap_testfile_q" SIGalrm || return 1
}

doTest3() {
	title='send signal, execute traps'
	kill -s ALRM "$$"
	if not is nonempty "$trap_testfile"; then
		return 1
	fi
}

doTest4() {
	title='unset POSIX trap'
	trap - ALRM || return 1
}

doTest5() {
	title='pop traps'
	failmsg='trap 3'
	poptrap alrm || return 1
	traptest_3=$REPLY
	failmsg='trap 2'
	poptrap SIGALRM || return 1
	traptest_2=$REPLY
	failmsg='trap 1'
	poptrap sigalrm || return 1
	traptest_1=$REPLY
	failmsg='stack not empty'
	poptrap ALRM && return 1
	eq $? 1
}

doTest6() {
	title='check output'
	identic $(cat $trap_testfile) trap3ok${CCn}trap2ok${CCn}trap1ok${CCn}POSIX-trap
}

lastTest=6
