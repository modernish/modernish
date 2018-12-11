#! test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# Regression tests related to loops and conditional constructs.

goodLoopResult="\
1: 1 2 3 4 5 6 7 8 9 10 11 12
2: 1 2 3 4 5 6 7 8 9 10 11 12
3: 1 2 3 4 5 6 7 8 9 10 11 12
4: 1 2 3 4 5 6 7 8 9 10 11 12"

doTest1() {
	title="nested 'LOOP for' (C style)"
	# BUG_ALIASCSUB compat (mksh < R55): in a $(comsub), have a command on same line as DO
	loopResult=$(
		thisshellhas BUG_ARITHTYPE && y=
		LOOP for "y=01; y<=4; y+=1"
		DO	put "$y:"
			LOOP for "x=1; x<=0x0C; x+=1"
			DO	put " $x"
			DONE
			putln
		DONE
	)
	identic $loopResult $goodLoopResult
}

doTest2() {
	title="nested 'LOOP for' (BASIC style)"
	# BUG_ALIASCSUB compat (mksh < R55): in a $(comsub), have a command on same line as DO
	loopResult=$(
		LOOP for y=0x1 to 4
		DO	put "$y:"
			LOOP for x=1 to 0x0C
			DO	put " $x"
			DONE
			putln
		DONE
	)
	identic $loopResult $goodLoopResult
}

doTest3() {
	title="nested 'LOOP repeat' (zsh style)"
	# BUG_ALIASCSUB compat (mksh < R55): in a $(comsub), have a command on same line as DO
	loopResult=$(
		y=0
		LOOP repeat 4
		DO	inc y
			put "$y:"
			x=0
			LOOP repeat 0x0C
			DO	inc x
				put " $x"
			DONE
			putln
		DONE
	)
	identic $loopResult $goodLoopResult
}

doTest4() {
	title="'case' does not clobber exit status"
	setstatus 42
	case $? in
	( 42 )	foo=$? ;;
	( * )	failmsg='setstatus failed'
		return 1 ;;
	esac
	case $foo in
	( 42 )	mustNotHave BUG_CASESTAT ;;
	( 0 )	mustHave BUG_CASESTAT ;;
	( * )	return 1 ;;
	esac
}

doTest5() {
	title="native 'select' stores input in \$REPLY"
	if not thisshellhas --rw=select; then
		skipmsg="no 'select'"
		return 3
	fi
	v=$(thisshellhas BUG_HDOCMASK && umask 177
	REPLY='unknown bug'
	command eval 'select v in foo bar baz; do break; done 2>/dev/null' <<-EOF
	correct
	EOF
	putln $REPLY)
	case $v in
	( correct )
		mustNotHave BUG_SELECTRPL ;;
	( '' )	mustHave BUG_SELECTRPL ;;
	( * )	return 1 ;;
	esac
}

doTest6() {
	title="native 'select' clears \$REPLY on EOF"
	if not thisshellhas --rw=select; then
		skipmsg="no 'select'"
		return 3
	fi
	REPLY=bug
	command eval 'select v in foo bar baz; do break; done' </dev/null >/dev/null 2>&1
	if not isset REPLY; then
		failmsg='REPLY is unset'  # we don't know of a shell that does this
		return 1
	fi
	case $REPLY in
	( '' )	mustNotHave BUG_SELECTEOF ;;
	( bug )	mustHave BUG_SELECTEOF ;;
	( * )	return 1 ;;
	esac
}

doTest7() {
	title='native ksh/zsh/bash arithmetic for loops'
	loopResult=$(
		eval 'for ((y=1; y<=4; y+=1)); do
			put "$y:"
			for ((x=1; x<=0x0C; x+=1)); do
				put " $x"
			done
			putln
		done' 2>/dev/null
	)
	case $loopResult in
	( $goodLoopResult )
		mustHave ARITHFOR ;;
	( '' )	mustNotHave ARITHFOR && return 3 ;;
	( * )	return 1 ;;
	esac
}

doTest8() {
	title="zero-iteration 'for' leaves var unset"
	unset -v v
	if thisshellhas BUG_PSUBEMPT; then
		LOCAL +o nounset; BEGIN
			for v in $v; do :; done
		END
	else
		for v in ${v-}; do :; done
	fi
	not isset v
}

doTest9() {
	title='--glob removes non-matching patterns'
	unset -v foo
	LOOP for --split='!' --glob v in /dev/null/?*!!/dev/null/!/dev/null/foo!/dev/null*
	#		  ^ split by a glob character: test --split's BUG_IFS* resistance
	DO
		foo=${foo:+$foo,}$v
	DONE
	failmsg=$foo
	# We expect only the /dev/null* pattern to match. There is probably just
	# /dev/null, but theoretically there could be other /dev/null?* devices.
	contains ",$foo," ',/dev/null,'
}

doTest10() {
	title='LOOP parses OK in command substitutions'
	if not (eval 'v=$(LOOP repeat 1; DO
				putln okay
			DONE); identic $v okay') 2>/dev/null
	then
		# test both BUG_ALIASCSUB workarounds: either use backticks or put a statement on the same line after DO
		(eval 'v=`LOOP repeat 1; DO
				putln okay
			DONE` && identic $v okay &&
			v=$(LOOP repeat 1; DO putln okay
			DONE) && identic $v okay') \
		&& mustHave BUG_ALIASCSUB
	else
		mustNotHave BUG_ALIASCSUB
	fi
}

lastTest=10
