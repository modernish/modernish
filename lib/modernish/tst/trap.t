#! test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# Test the trap stack and POSIX traps.

trap_testfile="$testdir/trap.t test file"
( umask 077 && : > $trap_testfile ) || die
shellquote trap_testfile_q=$trap_testfile

TEST title='push;set;check;send sig;unset;pop;check'
	# one large test since every step depends on the previous one;
	# running these separately would cause them to fail
	# ------------------
	failmsg='push traps'
	push IFS -C -u
	failmsg='trap 1' \
	&& IFS=abc && set -C \
	&& pushtrap "v=trap1; str eq \"\$IFS\" abc && isset -C && putln 'trap1ok' >>$trap_testfile_q" ALRM \
	&& failmsg='trap 2' \
	&& IFS= && set +C \
	&& pushtrap "v=trap2; str empty \"\$IFS\" && not isset -C && putln 'trap2ok' >>$trap_testfile_q" SIGALRM \
	&& pushtrap --nosubshell 'v=trap2a' sigAlrm \
	&& failmsg='trap 3' \
	&& unset -v IFS && set +u \
	&& pushtrap "v=trap3; not isset IFS && not isset -u && putln 'trap3ok' >>$trap_testfile_q" sIgAlRm
	pop --keepstatus IFS -C -u || return 1
	# ------------------
	failmsg='set POSIX trap'
	trap "putln 'POSIX-trap' >>$trap_testfile_q" SIGalrm || return 1
	# ------------------
	failmsg='check traps, test var=$(trap)'
	case $(trap) in
	( *\
'pushtrap -- "v=trap1; str eq \"\$IFS\" abc && isset -C && putln '\'trap1ok\'' >>'*' ALRM
pushtrap -- "v=trap2; str empty \"\$IFS\" && not isset -C && putln '\'trap2ok\'' >>'*' ALRM
pushtrap --nosubshell -- "v=trap2a" ALRM
pushtrap -- "v=trap3; not isset IFS && not isset -u && putln '\'trap3ok\'' >>'*' ALRM
trap -- "putln '\'POSIX-trap\'' >>'*' ALRM'* )
		;;
	( * )	return 1 ;;
	esac
	# ------------------
	failmsg='send signal, execute traps'
	unset -v v
	kill -s ALRM "$$"
	if not isset v || not str eq $v 'trap2a'; then
		append failmsg ' (--nosubshell)'
	fi
	if not is nonempty "$trap_testfile"; then
		append failmsg ' (no output)'
	fi
	not isset failmsg
	# ------------------
	failmsg='unset POSIX trap'
	trap - ALRM || return 1
	# ------------------
	failmsg='pop trap 3' \
	&& poptrap -R alrm \
	&& str match $REPLY 'pushtrap -- *v=trap3;*trap3ok* ALRM' \
	&& failmsg='pop trap 2a' \
	&& poptrap -R aLRm \
	&& str match $REPLY 'pushtrap --nosubshell -- ?v=trap2a? ALRM' \
	&& failmsg='pop trap 2' \
	&& poptrap -R SIGALRM \
	&& str match $REPLY 'pushtrap -- *v=trap2;*trap2ok* ALRM' \
	&& failmsg='pop trap 1' \
	&& poptrap -R sigalrm \
	&& str match $REPLY 'pushtrap -- *v=trap1;*trap1ok* ALRM' \
	&& failmsg='pop traps: stack not empty' \
	&& { poptrap ALRM; eq $? 1; } \
	|| return 1
	# ------------------
	failmsg='check output'
	str eq $(PATH=$DEFPATH exec cat $trap_testfile) trap3ok${CCn}trap2ok${CCn}trap1ok${CCn}POSIX-trap
ENDT

# For test 2 and 3, use only signal names and numbers guaranteed by POSIX,
# *not* including 6/ABRT which may be called IOT on some systems.
# See: http://pubs.opengroup.org/onlinepubs/9699919799/utilities/kill.html#tag_20_64_04

TEST title='thisshellhas --sig=number'
	thisshellhas --sig=14 || return 1
	str eq $REPLY ALRM || return 1
ENDT

TEST title='thisshellhas --sig=name'
	thisshellhas --sig=siGqUit || return 1
	str eq $REPLY QUIT || return 1
ENDT

TEST title="'trap' deals with empty system traps"
	# Related to BUG_TRAPEMPT.  Without a workaround in _Msh_printSysTrap()
	# in bin/modernish, would die at 'trap >/dev/null'
	_Msh_arg2sig CONT || return 1
	v=${_Msh_sigv}
	trap - CONT \
	&& command trap '' CONT \
	&& not isset _Msh_POSIXtrap$v \
	&& trap >/dev/null \
	&& isset _Msh_POSIXtrap$v \
	&& eval "str empty \${_Msh_POSIXtrap$v}" \
	&& trap - CONT \
	&& not isset _Msh_POSIXtrap$v \
	|| return 1
ENDT

TEST title='ERR and ZERR are properly aliased'
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
ENDT

TEST title="'trap' can output ERR traps"
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
	&& str match $v *'pushtrap -- ": one" ERR'$CCn'pushtrap -- ": two" ERR'$CCn'trap -- ": final" ERR'* \
	|| return 1
ENDT

TEST title='trap stack in a subshell'
	# Tests that the first 'trap' or 'pushtrap' in a subshell clears the parent shell's
	# native and modernish traps (except DIE), and that 'pushtrap' works as expected in subshells.
	# ...skip test if we're ignoring SIGTERM
	{ $MSH_SHELL -c 'kill -s TERM $$'; } 2>/dev/null && skipmsg='SIGTERM already ignored' && return 3
	# ...ignore DIE traps, as well as any hard-ignored signals in 'trap' output (bash on some systems)
	ignoredSigs=$(trap - QUIT; trap)
	str empty $ignoredSigs && unset -v ignoredSigs \
	|| case $(putln $ignoredSigs | sed '/ DIE$/ d') in
	( '' )	# only DIE traps: ok
		;;
	( *trap\ --\ \'[!\']* | *trap\ --\ \"[!\"]* | *trap\ --\ \$\'[!\']* )
		# non-ignored signals in output
		unset -v ignoredSigs
		failmsg='traps not reset in subshell'
		return 1 ;;
	( *trap\ --\ \'\'\ * | *trap\ --\ \"\"\ * | *trap\ --\ \$\'\'\ * )
		# remember hard-ignored and DIE traps
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
	# ...remove any hard-ignored signals and DIE traps from the output
	if isset ignoredSigs; then
		v=$(putln "$v" | harden -c -p -e '> 1' grep -F -v -e "$ignoredSigs")
		unset -v ignoredSigs
		str empty "$v" && failmsg="wrong output from 'trap' (2)" && return 1
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
		# TODO: this is only on zsh <= 5.0.8; make FAIL when support stops
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
	( * )	if not { thisshellhas --sig=$e && str eq $REPLY TERM; }; then
			failmsg="wrong exit status $e${REPLY+ ($REPLY)}"
			return 1
		fi ;;
	esac
ENDT

TEST title="'trap' can ignore sig if no stack traps"
	# A properly ignored signal passes the ignoring on. Test for this.
	{ $MSH_SHELL -c 'kill -s USR1 $$'; } 2>/dev/null && skipmsg='SIGUSR1 already ignored' && return 3
	(
		trap '' USR1
		pushtrap ': foo' USR1			# this should disable ignoring for child processes
		{ $MSH_SHELL -c 'kill -s USR1 $$'; } 2>/dev/null
		e=$?
		eq $e 0 && exit 13
		thisshellhas --sig=$e && str eq $REPLY USR1 || exit 14
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
		str eq $REPLY USR1 && failmsg='not ignored for current process' || failmsg=$e/$REPLY
		return 1 ;;
	esac
ENDT

TEST title="'trap' builtin produces correct output"
	# Regression test for BUG_TRAPEMPT and BUG_TRAPEXIT detection
	v=$(	command trap '' 0  # BUG_TRAPEXIT compat
		command trap)
	case $CCn$v$CCn in
	( *$CCn"trap -- '' EXIT"$CCn* )
		mustNotHave BUG_TRAPEMPT && mustNotHave BUG_TRAPEXIT ;;
	( *$CCn"trap -- '' 0"$CCn* )
		mustNotHave BUG_TRAPEMPT && mustHave BUG_TRAPEXIT ;;
	( *$CCn"trap --  EXIT"$CCn* )
		mustNotHave BUG_TRAPEXIT && mustHave BUG_TRAPEMPT ;;
	( *$CCn"trap -- '' "$CCn* )
		xfailmsg='intermittent zsh 5.0.* EXIT bug'
		str match ${ZSH_VERSION-} 5.0.[78] && return 2 ;;
	( * )	return 1 ;;
	esac
ENDT

TEST title='subshell exit status within traps'
	# Test the 10 known variants of BUG_TRAPSUB0, plus 2 that aren't known to exist in the wild.
	# All known shells with some BUG_TRAPSUB0 variants have variant e5, so that one is used in cap/BUG_TRAPSUB0.t.
	{ v=$(
		PATH=$DEFPATH  # make 'true', 'false' and 'kill' available (no, they are not quite always built in)
		if runExpensive; then
			trapcmd=pushtrap  # Resetting the modernish trap stack again for each (subshell) is slow...
			exit=EXIT	  # ...but is a good way of more thoroughly testing modernish bug workarounds.
		else
			trapcmd=trap	  # Use 'trap' builtin, bypassing modernish 'trap' alias.
			thisshellhas BUG_TRAPEXIT && exit=0 || exit=EXIT
		fi
		# ... EXIT trap ...
		($trapcmd '(false) && put E1,' $exit)	# 'false'/'true': regular builtins
		($trapcmd '(! :) && put E2,' $exit)	# ':': special builtin
		($trapcmd '(true) || put E3,' $exit; false)
		($trapcmd '(:) || put E4,' $exit; false)
		($trapcmd 'unset -v v; readonly v; (v=foo) 2>/dev/null && put E5,' $exit)
		($trapcmd '(set -o bad@option 2>/dev/null) && put E6,' $exit)
		# ... signals ...
		thisshellhas WRN_NOSIGPIPE && sig=TERM || sig=PIPE
		($trapcmd '(false) && put S1,' $sig; insubshell -p; kill -s $sig $REPLY)
		($trapcmd '(! :) && put S2,' $sig; insubshell -p; kill -s $sig $REPLY)
		($trapcmd '(true) || put S3,' $sig; insubshell -p; false; kill -s $sig $REPLY)
		($trapcmd '(:) || put S4,' $sig; insubshell -p; false; kill -s $sig $REPLY)
		($trapcmd 'unset -v v; readonly v; (v=foo) 2>/dev/null && put S5,' $sig; insubshell -p; kill -s $sig $REPLY)
		$trapcmd '(set -o bad@option 2>/dev/null) && put S6,' $sig; insubshell -p; kill -s $sig $REPLY
	); }
	case $v in
	( *S3,* | *S4,* ) # No shell is currently known to trigger these
		failmsg="unknown result: ${v%,}"; return 1 ;;
	( *, )	xfailmsg=${v%,}; failmsg=$xfailmsg; mustHave BUG_TRAPSUB0 ;;
	( '' )	mustNotHave BUG_TRAPSUB0 ;;
	( * )	return 1 ;;
	esac
ENDT
