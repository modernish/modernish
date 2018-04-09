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

doTest11() {
	title='ERR and ZERR are properly aliased'
	if not thisshellhas --sig=ZERR; then
		skipmsg='no --sig=ZERR'
		return 3
	fi
	case $(	command trap - ZERR ERR || exit
		command trap 'put one' ZERR
		command false
		command trap 'put two' ERR
		command false
	     ) in
	( onetwo )
		mustHave TRAPZERR ;;
	( oneone )
		mustNotHave TRAPZERR ;;
	( * )	return 1 ;;
	esac
}

doTest12() {
	title="'trap' can output ERR traps"
	if not thisshellhas --sig=ERR; then
		skipmsg='no --sig=ERR'
		return 3
	fi
	pushtrap ': one' ERR \
	&& pushtrap ': two' ERR \
	&& trap ': final' ERR \
	&& v=$(trap) \
	&& trap - ERR \
	&& poptrap ERR \
	&& poptrap ERR \
	&& match $v *'pushtrap -- ": one" ERR'$CCn'pushtrap -- ": two" ERR'$CCn'trap -- ": final" ERR'* \
	|| return 1
}

doTest13() {
	title='trap stack in a subshell'
	# Tests that the first 'trap' or 'pushtrap' in a subshell clears the parent shell's
	# native and modernish traps, and that 'pushtrap' works as expected in subshells.
	# ...skip test if we're ignoring SIGTERM
	{ $MSH_SHELL -c 'kill -s TERM $$'; } 2>/dev/null && skipmsg='SIGTERM already ignored' && return 3
	# ...detect if this shell hardcodes ignored signals in 'trap' output (bash on some systems)
	ignoredSigs=$(trap - QUIT; trap)
	case $ignoredSigs in
	( '' )	unset -v ignoredSigs ;;
	( *trap\ --\ \'[!\']* | *trap\ --\ \"[!\"]* | *trap\ --\ \$\'[!\']* )
		# non-ignored signals in output
		unset -v ignoredSigs
		failmsg='traps not reset in subshell'
		return 1 ;;
	( *trap\ --\ \'\'\ * | *trap\ --\ \"\"\ * | *trap\ --\ \$\'\'\ * )
		# remember hard-ignored traps
		;;
	( * )	unset -v ignoredSigs
		failmsg="wrong output from 'trap' (1)"
		return 1 ;;
	esac
	# ...now actually test the trap stack in a subshell
	{ v=$(	exec 2>&3
		pushtrap ': 1' usr1
		pushtrap ': 2' usr1
		pushtrap 'putln BYE' term
		pushtrap 'putln bye' TERM
		trap
		insubshell -p && kill -s term $REPLY && putln no_exit && exit
		putln FAIL
	); } 3>&2 2>/dev/null	# the redirections suppress "Terminated: 15" on dash & bash while saving xtrace
	e=$?
	# ...remove any hard-ignored signals from the output
	if isset ignoredSigs; then
		v=$(putln "$v" | harden -c -p -e '> 1' grep -F -v -e "$ignoredSigs")
		unset -v ignoredSigs
		empty "$v" && failmsg="wrong output from 'trap' (2)" && return 1
	fi
	# ...validate the output
	: v=$v	# show in xtrace
	t1="pushtrap -- \": 1\" USR1${CCn}pushtrap -- \": 2\" USR1${CCn}"
	t2="pushtrap -- \"putln BYE\" TERM${CCn}pushtrap -- \"putln bye\" TERM${CCn}"
	case $v in
	( ${t1}${t2}bye${CCn}BYE \
	| ${t2}${t1}bye${CCn}BYE )
		;;
	( ${t1}${t2}no_exit \
	| ${t2}${t1}no_exit )
		failmsg='signal not caught'
		return 1 ;;
	( ${t1}${t2}no_exit${CCn}bye${CCn}BYE \
	| ${t2}${t1}no_exit${CCn}bye${CCn}BYE )
		xfailmsg='no instant exit on signal'
		return 2 ;;
	( *FAIL )
		failmsg="'insubshell -p' failed"
		return 1 ;;
	( * )
		failmsg="wrong output from 'trap' (3)"
		return 1 ;;
	esac
	# ...validate the exit status
	case $e in
	( 0 )	xfailmsg='shell bug: status 0 on signal'
		return 2 ;;
	( * )	if not thisshellhas --sig=$e && identic $REPLY TERM; then
			failmsg="wrong exit status $e${REPLY+ ($REPLY)}"
			return 1
		fi ;;
	esac
}

doTest14() {
	title="'trap' can ignore sig if no stack traps"
	# A properly ignored signal passes the ignoring on. Test for this.
	{ $MSH_SHELL -c 'kill -s USR1 $$'; } 2>/dev/null && skipmsg='SIGUSR1 already ignored' && return 3
	(
		trap '' USR1
		pushtrap ': foo' USR1			# this should disable ignoring for child processes
		{ $MSH_SHELL -c 'kill -s USR1 $$'; } 2>/dev/null
		e=$?
		eq $e 0 && exit 13
		thisshellhas --sig=$e && identic $REPLY USR1 || exit 14
		insubshell -p && kill -s USR1 $REPLY	# make sure ignoring still works for the current process
		poptrap USR1				# this should restore ignoring for child processes
		{ $MSH_SHELL -c 'kill -s USR1 $$'; } 2>/dev/null
		eq $? 0 || exit 15
	) & wait "$!"	# force the subshell to fork a new process on ksh93
	e=$?
	case $e in
	( 0 )	;;
	( 13 )	failmsg='ignored while stack traps'
		return 1 ;;
	( 14 )	failmsg='wrong exit code'
		return 1 ;;
	( 15 )	failmsg='not ignored while no stack traps'
		return 1 ;;
	( * )	thisshellhas --sig=$e || { failmsg=$e; return 1; }
		identic $REPLY USR1 && failmsg='not ignored for current process' || failmsg=$e/$REPLY
		return 1 ;;
	esac
}

lastTest=14
