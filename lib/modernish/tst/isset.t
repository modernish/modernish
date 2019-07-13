#! test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

TEST title='isset -r: an unset readonly'
	unset -v unsetro
	readonly unsetro
	isset -r unsetro && not isset -v unsetro
ENDT

TEST title='isset -r: a set readonly'
	readonly setro=foo
	isset -v setro && isset -r setro || return 1
ENDT

TEST title='isset -r: an unset non-readonly'
	unset -v unsetnonro
	! isset -v unsetnonro && ! isset -r unsetnonro
ENDT

TEST title='isset -r: a set non-readonly'
	setnonro=foo
	isset -v setnonro && ! isset -r setnonro || return 1
ENDT

TEST title='isset -x: an unset exported variable'
	unset -v unsetex
	export unsetex
	if not isset -x unsetex; then
		failmsg='export failed'
		return 1
	fi
	v=$(PATH=$DEFPATH $MSH_SHELL -c 'echo ${unsetex+EX}${unsetex-NO}')
	unexport unsetex
	# There is no known shell that has both BUG_NOUNSETEX and BUG_EXPORTUNS, so fail on the combination.
	if not isset -v unsetex; then
		case $v in
		( EX )	mustNotHave BUG_NOUNSETEX && mustHave BUG_EXPORTUNS ;;
		( NO )	mustNotHave BUG_NOUNSETEX && mustNotHave BUG_EXPORTUNS ;;
		( * )	return 1 ;;
		esac
	else
		case $v in
		( NO )	mustNotHave BUG_EXPORTUNS && mustHave BUG_NOUNSETEX ;;
		( * )	return 1 ;;
		esac
	fi
ENDT

TEST title='isset -x: a set exported variable'
	# try to fool the parsing of 'export -p'...
	export setex="foo${CCn}export setnonex='bar'"
	unset -v setnonex || return 1
	setnonex=bar
	isset -v setex && isset -x setex || return 1
	failmsg='isset -x fooled'
	not isset -x setnonex
ENDT

TEST title='isset -x: an unset non-exported variable'
	unset -v unsetnonex
	! isset -v unsetnonex && ! isset -x unsetnonex
ENDT

TEST title='isset -x: a set non-exported variable'
	setnonex=foo
	isset -v setnonex && ! isset -x setnonex || return 1
ENDT

TEST title='isset -r/-x: an unset exported readonly'
	unset -v unsetrx
	export unsetrx
	readonly unsetrx
	if not isset -r unsetrx || not isset -x unsetrx; then
		failmsg='export/readonly failed'
		return 1
	fi
	v=$(PATH=$DEFPATH $MSH_SHELL -c 'echo ${unsetrx+EX}${unsetrx-NO}')
	# There is no known shell that has both BUG_NOUNSETEX and BUG_EXPORTUNS, so fail on the combination.
	if not isset -v unsetrx; then
		case $v in
		( EX )	mustNotHave BUG_NOUNSETEX && mustHave BUG_EXPORTUNS ;;
		( NO )	mustNotHave BUG_NOUNSETEX && mustNotHave BUG_EXPORTUNS ;;
		( * )	return 1 ;;
		esac
	else
		case $v in
		( EX )	mustNotHave BUG_EXPORTUNS && mustHave BUG_NOUNSETEX ;;
		( * )	return 1 ;;
		esac
	fi
ENDT

TEST title='isset -r/-x: a set exported readonly'
	export setrx=foo
	readonly setrx
	isset -v setrx && isset -r setrx && isset -x setrx || return 1
ENDT

TEST title='isset -f: an unset function'
	unset -f _Msh_nofunction
	! isset -f _Msh_nofunction
ENDT

TEST title='isset -f: a set function'
	isset -f doTest || return 1
ENDT

TEST title='isset -f: a readonly function'
	if ! thisshellhas ROFUNC; then
		skipmsg='no ROFUNC'
		return 3
	fi
	(
		_Msh_testFn() { :; }
		readonly -f _Msh_testFn && isset -f _Msh_testFn
	) || return 1
ENDT

TEST title='isset: an unset short shell option'
	push -f
	set +f
	! isset -f
	pop --keepstatus -f
ENDT

TEST title='isset: a set short shell option'
	push -f
	set -f
	isset -f
	pop --keepstatus -f || return 1
ENDT

TEST title='isset -o: an unset long shell option'
	push -u
	set +u
	! isset -o nounset
	pop --keepstatus -u
ENDT

TEST title='isset -o: a set long shell option'
	push -u
	set -u
	isset -o nounset
	pop --keepstatus -u || return 1
ENDT

TEST title='isset -o: nonexistent long shell option'
	# verify that nonexistent is treated as not set
	v=$(isset -o E721BCDF-F874-4E71-B395-470A1071BBDC; putln $?)
	case $v in
	( '' )	failmsg='shell exits'
		return 1 ;;
	( 1 )	;;
	( * )	failmsg="status $v"
		return 1 ;;
	esac
ENDT

TEST title='isset (-v): an unset variable'
	unset -v test18_unset
	! isset -v test18_unset && ! isset test18_unset
ENDT

TEST title='isset (-v): a set variable'
	isset -v title && isset title || return 1
ENDT

TEST title='isset (-v): unset IFS'
	if thisshellhas BUG_IFSISSET; then
		okmsg='BUG_IFSISSET worked around'
		failmsg='BUG_IFSISSET workaround failed'
	fi
	push IFS
	unset -v IFS
	! isset -v IFS && ! isset IFS
	pop --keepstatus IFS
ENDT

TEST title='isset (-v): set, empty IFS'
	if thisshellhas BUG_IFSISSET; then
		okmsg='BUG_IFSISSET worked around'
		failmsg='BUG_IFSISSET workaround failed'
	fi
	push IFS
	IFS=
	isset -v IFS && isset IFS
	pop --keepstatus IFS || return 1
ENDT

TEST title='isset (-v): set, nonempty IFS'
	if thisshellhas BUG_IFSISSET; then
		okmsg='BUG_IFSISSET worked around'
		failmsg='BUG_IFSISSET workaround failed'
	fi
	push IFS
	IFS=" $CCt$CCn"
	isset -v IFS && isset IFS
	pop --keepstatus IFS || return 1
ENDT

TEST title='param subst can test if IFS is set'
	push IFS
	unset -v IFS
	case ${IFS+set} in
	( set )	not isset -v IFS && mustHave BUG_IFSISSET ;;
	( '' )	not isset -v IFS && mustNotHave BUG_IFSISSET ;;
	( * )	failmsg=weird; setstatus 1 ;;
	esac
	pop --keepstatus IFS
ENDT

TEST title='IFS can be unset'
	# see cap/BUG_KUNSETIFS.t for explanation
	push IFS
	IFS=
	if eval "(unset -v IFS; isset -v IFS)"; then
		mustHave BUG_KUNSETIFS || return
		# test if the workaround works
		if ! eval "(IFS=foobar; unset -v IFS; isset -v IFS')"; then
			setstatus 2
		else
			failmsg='BUG_KUNSETIFS workaround fails'
			setstatus 1
		fi
	else
		mustNotHave BUG_KUNSETIFS
	fi
	pop --keepstatus IFS
ENDT

TEST title='local assignments with regular builtins'
	v=$(	# QRK_SPCBIEXP and BUG_SPCBILOC compat: run in subshell
		v=1
		# special builtins: assignments should persist
		v=2 set foo
		eq v 2 || exit
		v=3 :
		eq v 3 || exit
		# regular builtins: assignments should *not* persist
		v=4 pwd >/dev/null
		v=5 read REPLY </dev/null
		eq v 3 || exit
		# test that 'command' makes special builtins nonspecial
		v=6 command eval :
		putln $v
	)
	case $v in
	( 3 )	mustNotHave BUG_CMDSPASGN ;;
	( 6 )	mustHave BUG_CMDSPASGN ;;
	( * )	return 1 ;;
	esac
ENDT

TEST title='function can be unset in subshell'
	foo() { :; }
	if (unset -f foo; isset -f foo); then
		mustHave BUG_FNSUBSH
	else
		mustNotHave BUG_FNSUBSH
	fi
ENDT

TEST title='function can be redefined in subshell'
	(mustHave() { return 13; }; mustHave BUG_FNSUBSH)
	case $? in
	( 13 )	mustNotHave BUG_FNSUBSH ;;
	( 2 )	mustHave BUG_FNSUBSH ;;
	( * )	return 1 ;;
	esac
ENDT

TEST title='"isset -r" works in traps'
	v=$(readonly v; pushtrap 'isset -r v && putln ok || putln bad' EXIT)
	case $v in
	( ok )	;;
	( bad )	thisshellhas BUG_TRAPSUB0 && failmsg='BUG_TRAPSUB0 workaround failed?' && return 1 ;;
	( * )	failmsg='other bug'; return 1 ;;
	esac
ENDT
