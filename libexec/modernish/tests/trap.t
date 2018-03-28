#! test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# Test the trap stack and POSIX traps.

mktemp -sCCC "/tmp/trap.t test 1.XXXXXX"
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
	title='check traps, test var=$(trap)'
	contains $(trap) \
"pushtrap -- 'identic \"\$IFS\" abc && isset -C && putln '\''trap1ok'\'' >>${trap_testfile_q}' ALRM
pushtrap -- 'empty \"\$IFS\" && not isset -C && putln '\''trap2ok'\'' >>${trap_testfile_q}' ALRM
pushtrap -- 'not isset IFS && not isset -u && putln '\''trap3ok'\'' >>${trap_testfile_q}' ALRM
trap -- 'putln '\''POSIX-trap'\'' >>${trap_testfile_q}' ALRM"
}

doTest4() {
	title='send signal, execute traps'
	kill -s ALRM "$$"
	if not is nonempty "$trap_testfile"; then
		return 1
	fi
}

doTest5() {
	title='unset POSIX trap'
	trap - ALRM || return 1
}

doTest6() {
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

doTest7() {
	title='check output'
	identic $(PATH=$DEFPATH exec cat $trap_testfile) trap3ok${CCn}trap2ok${CCn}trap1ok${CCn}POSIX-trap
}

# For test 8 and 9, use only signal names and numbers guaranteed by POSIX,
# *not* including 6/ABRT which may be called IOT on some systems.
# See: http://pubs.opengroup.org/onlinepubs/9699919799/utilities/kill.html#tag_20_64_04

doTest8() {
	title='thisshellhas --sig=number'
	thisshellhas --sig=14 || return 1
	identic $REPLY ALRM || return 1
}

doTest9() {
	title='thisshellhas --sig=name'
	thisshellhas --sig=siGqUit || return 1
	identic $REPLY QUIT || return 1
}

doTest10() {
	title="'trap' deals with empty system traps"
	# Related to BUG_TRAPEMPT.  Without a workaround in _Msh_printSysTrap()
	# in bin/modernish, would die at 'trap >/dev/null'
	_Msh_arg2sig CONT || return 1
	v=${_Msh_sigv}
	trap - CONT \
	&& command trap '' CONT \
	&& not isset _Msh_POSIXtrap$v \
	&& trap >/dev/null \
	&& isset _Msh_POSIXtrap$v \
	&& eval "empty \${_Msh_POSIXtrap$v}" \
	&& trap - CONT \
	&& not isset _Msh_POSIXtrap$v \
	|| return 1
}

lastTest=10
