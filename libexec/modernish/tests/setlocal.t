#! test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# Regression tests for var/setlocal, as well as shell-native implementations of local variables.


# --- var/setlocal module ---

doTest1() {
	title='local globbing'
	set -- /*
	setlocal file +o noglob; do
		set -- /*
		okmsg=$#
		failmsg=$#
		for file do
			startswith "$file" / || return
			is present "$file" || return
			#	   ^^^^^^^ must quote as globbing is active within this block
		done
		gt $# 1
	endlocal || return
	eq $# 1
}

doTest2() {
	title='glob arguments'
	setlocal file --glob -- /*; do
		okmsg=$#
		failmsg=$#
		for file do
			startswith $file / || return
			is present $file || return
			#	   ^^^^^ no quoting needed here: globbing was only applied to setlocal args
		done
		gt $# 1
	endlocal
}


doTest3() {
	title='nested local vars, opts, field splitting'
	push X Y
	X=12 Y=13
	setlocal X=2 Y=4 +o noclobber splitthis='this string should not be subject to fieldsplitting.'; do
		set -- $splitthis
		identic $X 2 && identic $Y 4 && not isset -C && eq $# 1 || return
		setlocal X=hi Y=there -o noclobber IFS=' ' splitthis='look ma, i can do local fieldsplitting!'; do
			set -- $splitthis
			identic $X hi && identic $Y there && isset -C && eq $# 7 || return
			X=13 Y=37
		endlocal || return
		identic $X 2 && identic $Y 4 && not isset -C && eq $# 1 || return
		X=123 Y=456
	endlocal || return
	identic $X 12 && identic $Y 13 && isset -C
	pop --keepstatus X Y
}

doTest4() {
	title='split arguments'
	setlocal --split=: -- one:two:three; do
		identic "$#,${1-},${2-},${3-}" "3,one,two,three"
	endlocal
}

# BUG_FNSUBSH:
# Running setlocal in a non-forked subshell on ksh93 would cause the WRONG temporary function
# to be executed (in this case, the 'NestedLocal' one above). So, running setlocal in a
# non-forked subshell does not work on ksh93. Modernish tests if unsetting/redefining the
# function if possible, and if not, it will kill the program rather than execute the wrong
# code. But there is a workaround that only works for command substitution subshells (which
# var/setlocal.mm has implemented (see there for details), so test that workaround here.
doTest5() {
	title='BUG_FNSUBSH workaround in cmd subst'
	push result
	set -- one two three
	# (Due to a bug, mksh [up to R54 2016/11/11] throws a syntax error if you use $( ) instead of ` `.
	# Not that this really matters. Since command substitutions are subshells, in real-world programs
	# you would rarely need to use setlocal in a command substitution, if ever.)
	result=`setlocal IFS +f; do PATH=$DEFPATH printf '[%s] ' "$@"; endlocal`
	identic $result '[one] [two] [three] '
	pop --keepstatus result
}

# ksh93 has LEPIPEMAIN (last element of pipe is executed in main shell), so
# piping into setlocal should be fine in spite of BUG_FNSUBSH.
doTest6() {
	title='LEPIPEMAIN: piping into setlocal'
	skipmsg='no LEPIPEMAIN'
	thisshellhas LEPIPEMAIN || return 3
	push result
	result=
	putln one two three four | setlocal X IFS=$CCn; do while read X; do result="$result[$X] "; done; endlocal
	identic $result "[one] [two] [three] [four] "
	pop --keepstatus result
}

doTest7() {
	title='protection against stack corruption'
	setlocal testvar='foo'; do
		push var3
		push var3 var2
		push var3 var2 var1
		pop var3 var2 testvar var1   # this should fail due to a key mismatch
		let "$? == 2" || return 1
		stacksize --silent var3
		let "REPLY == 3" || return 1
		stacksize --silent var2
		let "REPLY == 2" || return 1
		stacksize --silent var1
		let "REPLY == 1" || return 1
	endlocal
	pop --keepstatus var3 var2 var1
	pop --keepstatus var3 var2
	pop --keepstatus var3
}


# --- shell-native implementations of local variables ---

doTest10() {
	title='native local vars: initial state'
	if not thisshellhas LOCAL; then
		skipmsg='no LOCAL'
		return 3
	fi
	# regression test for QRK_LOCALINH, QRK_LOCALSET and QRK_LOCALSET2 detection
	foo=global
	unset -v bar failmsg
	fooFn() {
		local foo bar
		case ${foo+FOOSET},${foo-FOOUNSET},${bar+BARSET},${bar-BARUNSET} in
		( ,FOOUNSET,,BARUNSET )
			# bash 4, pdksh/mksh, yash
			thisshellhas QRK_LOCALSET && failmsg=${failmsg:+$failmsg, }'QRK_LOCALSET wrongly detected'
			thisshellhas QRK_LOCALSET2 && failmsg=${failmsg:+$failmsg, }'QRK_LOCALSET2 wrongly detected'
			thisshellhas QRK_LOCALINH && failmsg=${failmsg:+$failmsg, }'QRK_LOCALINH wrongly detected'
			return 0 ;;
		( FOOSET,global,,BARUNSET )
			# dash, FreeBSD sh
			thisshellhas QRK_LOCALSET && failmsg=${failmsg:+$failmsg, }'QRK_LOCALSET wrongly detected'
			thisshellhas QRK_LOCALSET2 && failmsg=${failmsg:+$failmsg, }'QRK_LOCALSET2 wrongly detected'
			thisshellhas QRK_LOCALINH && okmsg=QRK_LOCALINH \
			|| failmsg=${failmsg:+$failmsg, }'QRK_LOCALINH not detected'
			;;
		( FOOSET,,BARSET, )
			# zsh
			thisshellhas QRK_LOCALSET2 && failmsg=${failmsg:+$failmsg, }'QRK_LOCALSET2 wrongly detected'
			thisshellhas QRK_LOCALINH && failmsg=${failmsg:+$failmsg, }'QRK_LOCALINH wrongly detected'
			thisshellhas QRK_LOCALSET && okmsg=QRK_LOCALSET \
			|| failmsg=${failmsg:+$failmsg, }'QRK_LOCALSET not detected'
			;;
		( ,FOOUNSET,BARSET, )
			# bash 2, 3
			thisshellhas QRK_LOCALSET && failmsg=${failmsg:+$failmsg, }'QRK_LOCALSET wrongly detected'
			thisshellhas QRK_LOCALINH && failmsg=${failmsg:+$failmsg, }'QRK_LOCALINH wrongly detected'
			thisshellhas QRK_LOCALSET2 && okmsg=QRK_LOCALSET2 \
			|| failmsg=${failmsg:+$failmsg, }'QRK_LOCALSET2 not detected'
			;;
		( * )	failmsg='unknown bug'
			return 1 ;;
		esac
	}
	fooFn && unset -f fooFn && not isset failmsg
}

doTest11() {
	title='native local vars: unsetting behaviour'
	if not thisshellhas LOCAL; then
		skipmsg='no LOCAL'
		return 3
	fi
	# regression test for QRK_LOCALUNS and QRK_LOCALUNS2 detection
	unset -v foo bar
	fooFn2() {
		unset -v foo
		case "${foo-U}" in
		( 1 )	thisshellhas QRK_LOCALUNS && return 0
			thisshellhas QRK_LOCALUNS2 && okmsg=QRK_LOCALUNS2 \
			|| failmsg=${failmsg:+$failmsg, }'QRK_LOCALUNS2 not detected' ;;
		( U )	thisshellhas QRK_LOCALUNS2 && failmsg=${failmsg:+$failmsg, }'QRK_LOCALUNS2 wrongly detected'
			return 0 ;;
		( 2 )	failmsg=${failmsg:+$failmsg, }'unknown quirk (2)' ;;
		( * )	failmsg=${failmsg:+$failmsg, }'internal error' ;;
		esac
	}
	fooFn() {
		local foo bar
		# QRK_LOCALUNS2 check:
		foo=2
		fooFn2 || return
		# QRK_LOCALUNS check:
		unset -v bar
		bar=global
	}
	foo=1
	fooFn || return 1
	unset -f fooFn fooFn2
	case ${bar+s},${bar-} in
	( s,global )
		thisshellhas QRK_LOCALUNS && okmsg=QRK_LOCALUNS || failmsg=${failmsg:+$failmsg, }'QRK_LOCALUNS not detected' ;;
	( , )	thisshellhas QRK_LOCALUNS && failmsg=${failmsg:+$failmsg, }'QRK_LOCALUNS wrongly detected' ;;
	( * )	failmsg=${failmsg:+$failmsg, }"unknown quirk (${bar+s},${bar-})" ;;
	esac
	not isset failmsg
}

doTest12() {
	title="empty words after '--' are preserved"
	setlocal --split -- '' '' 'foo bar baz' ''; do
		identic ${#},${1-},${2-},${3-},${4-},${5-},${6-} '6,,,foo,bar,baz,'
	endlocal
}

lastTest=12
