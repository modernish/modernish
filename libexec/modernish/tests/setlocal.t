#! test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

doTest1() {
	title='local globbing'
	set -- *
	{ setlocal --doglob
		set -- *
		gt $# 1
	endlocal } || return
	eq $# 1
}

doTest2() {
	title='nested local vars, opts, field splitting'
	push X Y
	X=12 Y=13
	{ setlocal X=2 Y=4 +o noclobber splitthis='this string should not be subject to fieldsplitting.'
		set -- $splitthis
		identic $X 2 && identic $Y 4 && not isset -C && eq $# 1 || return
		{ setlocal X=hi Y=there -o noclobber --dosplit splitthis='look ma, i can do local fieldsplitting!'
			set -- $splitthis
			identic $X hi && identic $Y there && isset -C && eq $# 7 || return
			X=13 Y=37
		endlocal } || return
		identic $X 2 && identic $Y 4 && not isset -C && eq $# 1 || return
		X=123 Y=456
	endlocal } || return
	identic $X 12 && identic $Y 13 && isset -C
	pop --keepstatus X Y
}

# BUG_FNSUBSH:
# Running setlocal in a non-forked subshell on ksh93 would cause the WRONG temporary function
# to be executed (in this case, the 'NestedLocal' one above). So, running setlocal in a
# non-forked subshell does not work on ksh93. Modernish tests if unsetting/redefining the
# function if possible, and if not, it will kill the program rather than execute the wrong
# code. But there is a workaround that only works for command substitution subshells (which
# var/setlocal.mm has implemented (see there for details), so test that workaround here.
doTest3() {
	title='BUG_FNSUBSH workaround in cmd subst'
	push result
	set -- one two three
	# (Due to a bug, mksh [up to R54 2016/11/11] throws a syntax error if you use $( ) instead of ` `.
	# Not that this really matters. Since command substitutions are subshells, in real-world programs
	# you would rarely need to use setlocal in a command substitution, if ever.)
	result=`{ setlocal --dosplit --doglob; PATH=$DEFPATH printf '[%s] ' "$@"; endlocal }`
	identic $result '[one] [two] [three] '
	pop --keepstatus result
}

# ksh93 has LEPIPEMAIN (last element of pipe is executed in main shell), so
# piping into setlocal should be fine in spite of BUG_FNSUBSH.
doTest4() {
	title='LEPIPEMAIN: piping into setlocal'
	skipmsg='no LEPIPEMAIN'
	thisshellhas LEPIPEMAIN || return 3
	push result
	result=
	putln one two three four | { setlocal X --split=$CCn; while read X; do result="$result[$X] "; done; endlocal }
	identic $result "[one] [two] [three] [four] "
	pop --keepstatus result
}

doTest5() {
	title='protection against stack corruption'
	{ setlocal testvar='foo'
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
	endlocal }
	pop --keepstatus var3 var2 var1
	pop --keepstatus var3 var2
	pop --keepstatus var3
}

lastTest=5
