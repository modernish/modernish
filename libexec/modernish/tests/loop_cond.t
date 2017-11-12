#! test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# Regression tests related to loops and conditional constructs.

goodLoopResult=\
'1: 1 2 3 4 5 6 7 8 9 10 11 12
2: 1 2 3 4 5 6 7 8 9 10 11 12
3: 1 2 3 4 5 6 7 8 9 10 11 12
4: 1 2 3 4 5 6 7 8 9 10 11 12
5: 1 2 3 4 5 6 7 8 9 10 11 12
6: 1 2 3 4 5 6 7 8 9 10 11 12
7: 1 2 3 4 5 6 7 8 9 10 11 12
8: 1 2 3 4 5 6 7 8 9 10 11 12
9: 1 2 3 4 5 6 7 8 9 10 11 12
10: 1 2 3 4 5 6 7 8 9 10 11 12
11: 1 2 3 4 5 6 7 8 9 10 11 12
12: 1 2 3 4 5 6 7 8 9 10 11 12'

doTest1() {
	title='nested cfor loops'
	loopResult=$(
		use loop/cfor
		eval 'cfor "y=1" "y<=12" "y+=1"; do
			put "$y:"
			cfor "x=1" "x<=0x0C" "x+=1"; do
				put " $x"
			done
			putln
		done'
	)
	identic $loopResult $goodLoopResult
}

doTest2() {
	title='nested sfor loops'
	loopResult=$(
		use loop/sfor
		use var/arith
		eval 'sfor "y=1" "le y 12" "inc y"; do
			put "$y:"
			sfor "x=1" "le x 0x0C" "inc x"; do
				put " $x"
			done
			putln
		done'
	)
	identic $loopResult $goodLoopResult
}

doTest3() {
	title='nested with loops'
	loopResult=$(
		use loop/with
		eval 'with y=1 to 12; do
			put "$y:"
			with x=1 to 0x0C; do
				put " $x"
			done
			putln
		done'
	)
	identic $loopResult $goodLoopResult
}

doTest4() {
	title="'case' does not clobber exit status"
	# regression test for BUG_CASESTAT
	false
	case $? in
	( 1 )	foo=$? ;;
	( * )	failmsg='unknown bug (1)'
		return 1 ;;
	esac
	case $foo in
	( 0 )	if thisshellhas BUG_CASESTAT; then
			xfailmsg=BUG_CASESTAT
			return 2
		else
			failmsg='BUG_CASESTAT not detected'
			return 1
		fi ;;
	( 1 )	return 0 ;;
	( * )	failmsg='unknown bug (2)'
		return 1 ;;
	esac
}

doTest5() {
	title="native 'select' stores input in \$REPLY"
	if not thisshellhas --rw=select; then
		skipmsg="no 'select'"
		return 3
	fi
	REPLY='unknown bug'
	command eval 'select v in foo bar baz; do break; done 2>/dev/null' <<-EOF
	correct
	EOF
	case $REPLY in
	( correct )
		return 0 ;;
	( '' )	if thisshellhas BUG_SELECTRPL; then
			xfailmsg=BUG_SELECTRPL
			return 2
		else
			failmsg='BUG_SELECTRPL not detected'
			return 1
		fi ;;
	esac
	failmsg=$REPLY
	return 1
}

lastTest=5
