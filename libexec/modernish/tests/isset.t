#! test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

doTest1() {
	title='isset -r: an unset readonly'
	# regression test for BUG_NOUNSETRO detection
	unset -v unsetro
	readonly unsetro
	if not isset -r unsetro; then
		return 1
	fi
	if not isset -v unsetro; then
		mustNotHave BUG_NOUNSETRO
	else
		mustHave BUG_NOUNSETRO
	fi
}

doTest2() {
	title='isset -r: a set readonly'
	readonly setro=foo
	isset -v setro && isset -r setro || return 1
}

doTest3() {
	title='isset -r: an unset non-readonly'
	unset -v unsetnonro
	! isset -v unsetnonro && ! isset -r unsetnonro
}

doTest4() {
	title='isset -r: a set non-readonly'
	setnonro=foo
	isset -v setnonro && ! isset -r setnonro || return 1
}

doTest5() {
	title='isset -x: an unset exported variable'
	unset -v unsetex
	export unsetex
	if not isset -x unsetex; then
		return 1
	fi
	if not isset -v unsetex; then
		mustNotHave BUG_NOUNSETEX
	else
		mustHave BUG_NOUNSETEX
	fi
}

doTest6() {
	title='isset -x: a set exported variable'
	# try to fool the parsing of 'export -p'...
	export setex="foo${CCn}export setnonex='bar'"
	unset -v setnonex || return 1
	setnonex=bar
	isset -v setex && isset -x setex || return 1
	failmsg='isset -x fooled'
	not isset -x setnonex
}

doTest7() {
	title='isset -x: an unset non-exported variable'
	unset -v unsetnonex
	! isset -v unsetnonex && ! isset -x unsetnonex
}

doTest8() {
	title='isset -x: a set non-exported variable'
	setnonex=foo
	isset -v setnonex && ! isset -x setnonex || return 1
}

doTest9() {
	title='isset -r/-x: an unset exported readonly' 
	unset -v unsetrx
	export unsetrx
	readonly unsetrx
	if not isset -r unsetrx || not isset -x unsetrx; then
		return 1
	fi
	if not isset -v unsetrx; then
		mustNotHave BUG_NOUNSETRO && mustNotHave BUG_NOUNSETEX
		return
	fi
	if thisshellhas BUG_NOUNSETRO BUG_NOUNSETEX; then
		xfailmsg='BUG_NOUNSET{RO,EX}'
		return 2
	else
		mustHave BUG_NOUNSETRO || mustHave BUG_NOUNSETEX
	fi
}

doTest10() {
	title='isset -r/-x: a set exported readonly'
	export setrx=foo
	readonly setrx
	isset -v setrx && isset -r setrx && isset -x setrx || return 1
}

doTest11() {
	title='isset -f: an unset function'
	unset -f _Msh_nofunction
	! isset -f _Msh_nofunction
}

doTest12() {
	title='isset -f: a set function'
	isset -f doTest12 || return 1
}

doTest13() {
	title='isset -f: a readonly function'
	if ! thisshellhas ROFUNC; then
		skipmsg='no ROFUNC'
		return 3
	fi
	(
		_Msh_testFn() { :; }
		readonly -f _Msh_testFn && isset -f _Msh_testFn
	) || return 1
}

doTest14() {
	title='isset: an unset short shell option'
	push -f
	set +f
	! isset -f
	pop --keepstatus -f
}

doTest15() {
	title='isset: a set short shell option'
	push -f
	set -f
	isset -f
	pop --keepstatus -f || return 1
}

doTest16() {
	title='isset -o: an unset long shell option'
	push -u
	set +u
	! isset -o nounset
	pop --keepstatus -u
}

doTest17() {
	title='isset -o: a set long shell option'
	push -u
	set -u
	isset -o nounset
	pop --keepstatus -u || return 1
}

doTest18() {
	title='isset (-v): an unset variable'
	unset -v test18_unset
	! isset -v test18_unset && ! isset test18_unset
}

doTest19() {
	title='isset (-v): a set variable'
	isset -v title && isset title || return 1
}

doTest20() {
	title='isset (-v): unset IFS'
	if thisshellhas BUG_IFSISSET; then
		okmsg='BUG_IFSISSET worked around'
		failmsg='BUG_IFSISSET workaround failed'
	fi
	push IFS
	unset -v IFS
	! isset -v IFS && ! isset IFS
	pop --keepstatus IFS
}

doTest21() {
	title='isset (-v): set, empty IFS'
	if thisshellhas BUG_IFSISSET; then
		okmsg='BUG_IFSISSET worked around'
		failmsg='BUG_IFSISSET workaround failed'
	fi
	push IFS
	IFS=
	isset -v IFS && isset IFS
	pop --keepstatus IFS || return 1
}

doTest22() {
	title='isset (-v): set, nonempty IFS'
	if thisshellhas BUG_IFSISSET; then
		okmsg='BUG_IFSISSET worked around'
		failmsg='BUG_IFSISSET workaround failed'
	fi
	push IFS
	IFS=" $CCt$CCn"
	isset -v IFS && isset IFS
	pop --keepstatus IFS || return 1
}

doTest23() {
	title='param subst can test if IFS is set'
	push IFS
	unset -v IFS
	case ${IFS+set} in
	( set )	not isset -v IFS && mustHave BUG_IFSISSET ;;
	( '' )	not isset -v IFS && mustNotHave BUG_IFSISSET ;;
	( * )	failmsg=weird; setstatus 1 ;;
	esac
	pop --keepstatus IFS
}

doTest24() {
	title='IFS can be unset'
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
}

doTest25() {
	title='local assignments with regular builtins'
	v=1
	# special builtins: assignments should persist
	v=2 set foo
	eq v 2 || return 1
	v=3 :
	eq v 3 || return 1
	# regular builtins: assignments should *not* persist
	v=4 pwd >/dev/null
	v=5 read REPLY </dev/null
	eq v 3 || return 1
	# test that 'command' makes special builtins nonspecial
	v=6 command eval :
	case $v in
	( 3 )	mustNotHave BUG_CMDSPASGN ;;
	( 6 )	mustHave BUG_CMDSPASGN ;;
	( * )	return 1 ;;
	esac
}

doTest26() {
	title='function can be unset in subshell'
	if (unset -f doTest26; isset -f doTest26); then
		mustHave BUG_FNSUBSH
	else
		mustNotHave BUG_FNSUBSH
	fi
}

doTest27() {
	title='function can be redefined in subshell'
	(mustHave() { return 13; }; mustHave BUG_FNSUBSH)
	case $? in
	( 13 )	mustNotHave BUG_FNSUBSH ;;
	( 2 )	mustHave BUG_FNSUBSH ;;
	( * )	return 1 ;;
	esac
}

lastTest=27
