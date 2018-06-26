#! test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# Regression tests related to (built-in) utilities of the shell.

doTest1() {
	title="options to 'command' can be expansions"
	v='-v'
	command $v : >/dev/null 2>&1
	case $? in
	( 0 )	mustNotHave BUG_CMDOPTEXP ;;
	# test suite runs with PATH=/dev/null, so we can rely on 127 = not found
	( 127 )	mustHave BUG_CMDOPTEXP ;;
	( * )	return 1 ;;
	esac
}

doTest2() {
	title="'command -v -p' searches default PATH"
	command -v -p chmod >/dev/null 2>&1 \
	&& command -v -p : >/dev/null 2>&1
	e=$?
	case $e in
	( 0 )	mustNotHave BUG_CMDPV ;;
	( 1 | 127 )
		if ( eval '[[ ${.sh.version} == Version\ *\ 201?-??-?? ]]' ) 2>/dev/null; then
			xfailmsg='ksh intermittent -p bug'
			# ref.: https://github.com/att/ast/issues/426
			return 2
		fi
		mustHave BUG_CMDPV ;;
	( * )	failmsg="e = $e"
		return 1 ;;
	esac
}

doTest3() {
	title="'command' prevents exit on 'set' error"
	v=$(command set +o bad@option 2>/dev/null; putln ok)
	case $v in
	( ok )	mustNotHave BUG_CMDSPEXIT ;;
	( '' )	mustHave BUG_CMDSPEXIT ;;
	( * )	return 1 ;;
	esac
}

doTest4() {
	title="'command -v' finds reserved words"
	v=$(command -v until)
	case $v in
	( until )
		mustNotHave BUG_CMDVRESV ;;
	( '' )	mustHave BUG_CMDVRESV ;;
	( * )	return 1 ;;
	esac
}

doTest5() {
	title="'break' works from within 'eval'"
	(
		for v in 0 1 2; do
			eval 'break' 2>/dev/null
			exit 13
		done
		exit 42
	)
	case $? in
	( 42 )	mustNotHave BUG_EVALCOBR ;;
	( * )	mustHave BUG_EVALCOBR ;;
	esac
}

doTest6() {
	title="'continue' works from within 'eval'"
	(
		for v in 1 2 42; do
			eval 'continue' 2>/dev/null
			break
		done
		exit $v
	)
	case $? in
	( 42 )	mustNotHave BUG_EVALCOBR ;;
	( * )	mustHave BUG_EVALCOBR ;;
	esac
}

doTest7() {
	title="\$LINENO works from within 'eval'"
	if not thisshellhas LINENO; then
		skipmsg='no LINENO'
		return 3
	fi
	v=$LINENO; eval "${CCn}x=\$LINENO${CCn}y=\$LINENO${CCn}z=\$LINENO${CCn}"
	if let "y == x + 1 && z == y + 1"; then
		mustNotHave BUG_LNNOEVAL
	elif let "x == v && y == v && z == v"; then
		mustNotHave BUG_LNNOEVAL && okmsg='no increment'
	elif let "x == 0 && y == 0 && z == 0"; then
		mustHave BUG_LNNOEVAL
	else
		failmsg="x==$x; y==$y; z==$z"
		return 1
	fi
}

doTest8() {
	title="\$LINENO works within alias expansion"
	if not thisshellhas LINENO; then
		skipmsg='no LINENO'
		return 3
	fi
	alias _util_test8="${CCn}x=\$LINENO${CCn}y=\$LINENO${CCn}z=\$LINENO${CCn}"
	# use 'eval' to force immediate alias expansion in function definition
	eval 'testFn() {
		_util_test8
	}'
	testFn
	unalias _util_test8
	unset -f testFn
	if let "y == x + 1 && z == y + 1"; then
		mustNotHave BUG_LNNOALIAS
	elif let "x == 0 && y == 0 && z == 0"; then
		mustHave BUG_LNNOALIAS
	elif let "y == x && z == y"; then
		mustNotHave BUG_LNNOALIAS && okmsg='no increment'
	else
		failmsg="x==$x; y==$y; z==$z"
		return 1
	fi
}

doTest9() {
	title="'export' can export readonly variables"
	v=$(
		msh_util_test9=ok
		readonly msh_util_test9
		export msh_util_test9 2>/dev/null
		$MSH_SHELL -c 'echo "$msh_util_test9"' 2>&1
	)
	case $v in
	( ok )	mustNotHave BUG_NOEXPRO ;;
	( '' )	mustHave BUG_NOEXPRO ;;
	( * )	return 1 ;;
	esac
}

doTest10() {
	title="shell options w/o ltrs don't affect \${-}"
	if not thisshellhas -o nolog; then
		skipmsg='no nolog option'
		return 3
	fi
	(
		set -C -o nolog
		v=abc${-}def${-}ghi
		set +o nolog
		identic $v abc$-def$-ghi
	) || mustHave BUG_OPTNOLOG
}

lastTest=10
