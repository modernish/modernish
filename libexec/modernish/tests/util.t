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

lastTest=4
