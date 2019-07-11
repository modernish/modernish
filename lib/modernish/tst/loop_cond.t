#! test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# Regression tests related to loops and conditional constructs.

goodLoopResult="\
1: 1 2 3 4 5 6 7 8 9 10 11 12
2: 1 2 3 4 5 6 7 8 9 10 11 12
3: 1 2 3 4 5 6 7 8 9 10 11 12
4: 1 2 3 4 5 6 7 8 9 10 11 12"


# ______ tests for POSIX loop and conditional constructs ________

TEST title="'case' does not clobber exit status"
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
ENDT

TEST title="loop won't clobber 'return' status [fn1]"
	fn() {
		while : foo && return 42 || : bar; do
			v=oops
			return 13
		done
	}
	unset -v v
	fn
	e=$?
	unset -f fn
	case $e in
	( 0 )	mustHave BUG_LOOPRET1 ;;
	( 42 )	mustNotHave BUG_LOOPRET1 ;;
	( * )	failmsg="$e${v+ ($v)}"; return 1 ;;
	esac
ENDT

TEST title="loop won't clobber 'return' status [dt1]"
	umask 022 && putln '
		while : foo && return 42 || : bar; do
			v=oops
			return 13
		done
	' > $testdir/BUG_LOOPRET1.sh && umask 777 || die
	unset -v v
	. $testdir/BUG_LOOPRET1.sh
	e=$?
	case $e in
	( 0 )	mustHave BUG_LOOPRET1 ;;
	( 42 )	mustNotHave BUG_LOOPRET1 ;;
	( * )	failmsg="$e${v+ ($v)}"; return 1 ;;
	esac
ENDT

TEST title="loop won't clobber 'return' status [fn2]"
	fn() {
		setstatus 42
		while return || : bar; do
			v=oops
			return 13
		done
	}
	unset -v v
	fn
	e=$?
	unset -f fn
	case $e in
	( 0 )	mustHave BUG_LOOPRET2 ;;
	( 42 )	mustNotHave BUG_LOOPRET2 ;;
	( * )	failmsg="$e${v+ ($v)}"; return 1 ;;
	esac
ENDT

TEST title="loop won't clobber 'return' status [dt2]"
	umask 022 && putln '
		setstatus 42
		while return || : bar; do
			v=oops
			return 13
		done
	' > $testdir/BUG_LOOPRET2.sh && umask 777 || die
	unset -v v
	. $testdir/BUG_LOOPRET2.sh
	e=$?
	case $e in
	( 0 )	mustHave BUG_LOOPRET2 ;;
	( 42 )	mustNotHave BUG_LOOPRET2 ;;
	( * )	failmsg="$e${v+ ($v)}"; return 1 ;;
	esac
ENDT

TEST title="control flow 'return' in loop cond. list"
	umask 022 && putln '
		until return 13; do
			:
		done
	' > $testdir/BUG_LOOPRET3.sh && umask 777 || die
	( . $testdir/BUG_LOOPRET3.sh; exit 42 )
	e=$?
	unset -f fn
	case $e in
	( 0 )	mustHave BUG_LOOPRET1
		eq $? 2 || return 1
		mustHave BUG_LOOPRET3 ;;
	( 13 )	mustHave BUG_LOOPRET3 ;;
	( 42 )	mustNotHave BUG_LOOPRET3 ;;
	( * )	failmsg=$e; return 1 ;;
	esac
ENDT

TEST title="zero-iteration 'for' leaves var unset"
	unset -v v
	if thisshellhas BUG_PSUBEMPT; then
		LOCAL +o nounset; BEGIN
			for v in $v; do :; done
		END
	else
		for v in ${v-}; do :; done
	fi
	not isset v
ENDT

TEST title="'for' does not make variable local"
	unset -v v
	fn() {
		for v in "${v-}" one two ok; do
			:
		done
	}
	fn
	case ${v-UNS} in
	( ok )	mustNotHave BUG_FORLOCAL ;;
	( UNS )	mustHave BUG_FORLOCAL ;;
	( * )	return 1 ;;
	esac
ENDT

# ______ tests for shell-specific loop and conditional constructs ________

TEST title="native 'select' stores input in \$REPLY"
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
		;;
	( * )	return 1 ;;
	esac
ENDT

TEST title="native 'select' clears \$REPLY on EOF"
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
ENDT

TEST title='native ksh/zsh/bash arithmetic for loops'
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
ENDT


# ______ tests for modernish LOOP (var/loop module) ________

TEST title="nested 'LOOP for' (C style)"
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
	str eq $loopResult $goodLoopResult
ENDT

TEST title="nested 'LOOP for' (BASIC style)"
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
	str eq $loopResult $goodLoopResult
ENDT

TEST title="nested 'LOOP repeat' (zsh style)"
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
	str eq $loopResult $goodLoopResult
ENDT

TEST title='--glob removes non-matching patterns'
	unset -v foo
	LOOP for --split='!' --glob v in /dev/null/?*!!/dev/null/!/dev/null/foo!/dev/null*
	#		  ^ split by a glob character: test --split's BUG_IFS* resistance
	DO
		foo=${foo:+$foo,}$v
	DONE
	failmsg=$foo
	# We expect only the /dev/null* pattern to match. There is probably just
	# /dev/null, but theoretically there could be other /dev/null?* devices.
	str in ",$foo," ',/dev/null,'
ENDT

TEST title='LOOP parses OK in command substitutions'
	if not (eval 'v=$(LOOP repeat 1; DO
				putln okay
			DONE); str eq $v okay') 2>/dev/null
	then
		# test both BUG_ALIASCSUB workarounds: either use backticks or put a statement on the same line after DO
		(eval 'v=`LOOP repeat 1; DO
				putln okay
			DONE` && str eq $v okay &&
			v=$(LOOP repeat 1; DO putln okay
			DONE) && str eq $v okay') \
		&& mustHave BUG_ALIASCSUB
	else
		mustNotHave BUG_ALIASCSUB
	fi
ENDT

TEST title="'LOOP find', simple check"
	# Check that:
	# - the -exec child shell inits and writes an iteration successfully
	# - breaking out of the loop prematurely works as expected
	v=
	LOOP find v in $MSH_MDL -type f; DO
		str match $v *.mm && break
	DONE
	e=$?
	if gt e 0; then
		failmsg="returned status $e"
		return 1
	elif not str match $v *.mm; then
		failmsg="found nothing; is $MSH_SHELL a shell that can run modernish?"
		return 1
	fi
ENDT

# For the next two expensive 'LOOP find' tests, first count the number of modules in $MSH_MDL
# using safe globbing (pathname expansion), so we can match the number against the results of 'LOOP find'.
if runExpensive; then
	dirpat=$MSH_MDL
	patterns=''
	# 8 levels of subdirectory should be plenty.
	LOOP repeat 8; DO
		dirpat=$dirpat/*
		append --sep=',' patterns $dirpat.mm
	DONE
	# So now $patterns is: .../modernish/*.mm,.../modernish/*/*.mm,.../modernish/*/*/*.mm,etc.
	# Expand these patterns, then count and store the results using local positional parameters.
	# Unlike normal global shell pathname expansion, the --glob operator removes non-matching patterns.
	LOCAL --split=',' --glob -- $patterns; BEGIN
		num_mods=$#
		all_mod_names=$(putln "$@" | sort)
	END
fi

TEST title="'LOOP find', varname, complex expression"
	runExpensive || return
	unset -v foo
	num_found=0
	names_found=''
	LOOP find --fglob v in $MSH_MDL/* \
		\( -path */cap -or -path */tests \) -prune \
		-or \( -type f -true -iterate \)
	DO
		str match $v *.mm || continue
		if not is reg $v || not str end $v .mm; then
			shellquote v
			failmsg="found wrong file: $v"
			return 1
		fi
		inc num_found
		append --sep=$CCn names_found $v
	DONE
	e=$?
	if gt e 0; then
		failmsg="returned status $e"
		return 1
	elif ne num_found num_mods; then
		if eq num_found 0; then
			failmsg="found nothing; is $MSH_SHELL a shell that can run modernish?"
		else
			failmsg="didn't find $num_mods files (found $num_found)"
		fi
		return 1
	elif not str eq $(putln $names_found | sort) $all_mod_names; then
		failmsg="names found don't match"
		return 1
	fi
ENDT

TEST title="'LOOP find', --xargs, complex expression"
	runExpensive || return
	unset -v foo
	num_found=0
	names_found=''
	LOOP find --fglob --xargs in $MSH_MDL/* \
		\( -path */cap -or -path */tests \) -prune \
		-or -type f -name *.mm -iterate
	DO
		inc num_found $#
		append --sep=$CCn names_found "$@"
	DONE
	e=$?
	if gt e 0; then
		failmsg="returned status $e"
		return 1
	elif ne num_found num_mods; then
		if eq num_found 0; then
			failmsg="found nothing; is $MSH_SHELL a shell that can run modernish?"
		else
			failmsg="didn't find $num_mods files (found $num_found)"
		fi
		return 1
	elif not str eq $(putln $names_found | sort) $all_mod_names; then
		failmsg="names found don't match"
		return 1
	fi
ENDT
