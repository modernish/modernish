#! test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# Regression tests related to loops and conditional constructs.

goodLoopResult="\
1: 1 2 3 4 5 6 7 8 9 10 11 12
2: 1 2 3 4 5 6 7 8 9 10 11 12
3: 1 2 3 4 5 6 7 8 9 10 11 12
4: 1 2 3 4 5 6 7 8 9 10 11 12"

all_mod_names=$(find $MSH_MDL -type f -name '*.mm' | sort)
num_mods=$(putln $all_mod_names | wc -l)

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

TEST title="'case' accepts an empty case list"
	(eval "case \${ERROR-} in${CCt}esac") 2>/dev/null
	case $? in
	( 0 )	mustNotHave BUG_CASEEMPT ;;
	( * )	mustHave BUG_CASEEMPT ;;
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
	' > $tempdir/BUG_LOOPRET1.sh && umask 777 || die
	unset -v v
	. $tempdir/BUG_LOOPRET1.sh
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
	' > $tempdir/BUG_LOOPRET2.sh && umask 777 || die
	unset -v v
	. $tempdir/BUG_LOOPRET2.sh
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
	' > $tempdir/BUG_LOOPRET3.sh && umask 777 || die
	( . $tempdir/BUG_LOOPRET3.sh; exit 42 )
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
	( '' )	;;
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
	loopResult=$(
		LOOP for "y=01; y<=4; y+=1"; DO
			put "$y:"
			LOOP for "x=1; x<=0x0C; x+=1"
			DO	put " $x"
			DONE
			putln
		DONE
	)
	str eq $loopResult $goodLoopResult
ENDT

TEST title="nested 'LOOP for' (BASIC style)"
	loopResult=$(
		LOOP for y=0x1 to 4; DO
			put "$y:"
			LOOP for x=1 to 0x0C
			DO	put " $x"
			DONE
			putln
		DONE
	)
	str eq $loopResult $goodLoopResult
ENDT

TEST title="nested 'LOOP repeat' (zsh style)"
	loopResult=$(
		y=0
		LOOP repeat 4; DO
			inc y
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
	if not can read /dev; then
		skipmsg="/dev not readable"
		return 3
	fi
	unset -v foo
	LOOP for --split='!' --glob v in /dev/null/?*!!/dev/null/!/dev/null/foo!/dev/null*
	#		  ^ split by a glob character: test --split's BUG_IFS* resistance
	DO
		foo=${foo:+$foo,}$v
	DONE
	failmsg=${foo-}
	# We expect only the /dev/null* pattern to match. There is probably just
	# /dev/null, but theoretically there could be other /dev/null?* devices.
	str in ",${foo-}," ',/dev/null,'
ENDT

TEST title='--glob rm non-matching patterns (--base)'
	if not can read /dev; then
		skipmsg="/dev not readable"
		return 3
	fi
	unset -v foo
	LOOP for --split='[' --glob --base=/dev v in null/?*[[null/[null/foo[null*
	#		  ^ split by a glob character: test --split's BUG_IFS* resistance
	DO
		foo=${foo:+$foo,}$v
	DONE
	failmsg=${foo-}
	# We expect only the null* pattern to match. There is probably just
	# /dev/null, but theoretically there could be other /dev/null?* devices.
	str in ",${foo-}," ',/dev/null,'
ENDT

TEST title='LOOP parses OK in command substitutions'
	(eval 'v=$(LOOP repeat 1; DO
		putln okay
	DONE); str eq $v okay') 2>/dev/null || return 1
ENDT

TEST title='LOOP body with here-doc with cmd subst'
	unset -v v
	{ v=$(	thisshellhas BUG_HDOCMASK && umask 077
		eval '	LOOP repeat 2; DO
				cat <<-EOF
				$(putln loopok)
				EOF
			DONE'
	); } 2>/dev/null || { mustHave BUG_ALIASCSHD; return; }
	str eq ${v-} loopok${CCn}loopok || return 1
	mustNotHave BUG_ALIASCSHD
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
	elif str empty $v; then
		failmsg="found nothing"
		return 1
	elif not str match $v $MSH_MDL/*.mm; then
		failmsg="found wrong file ($v)"
		return 1
	fi
ENDT

TEST title="'LOOP find', varname, complex expression"
	unset -v foo
	num_found=0
	names_found=''
	LOOP find --fglob --base=$MSH_MDL v in * \
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
	unset -v foo
	num_found=0
	names_found=''
	LOOP find --fglob --base=$MSH_MDL --xargs in * \
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
		failmsg="didn't find $num_mods files (found $num_found)"
		return 1
	elif not str eq $(putln $names_found | sort) $all_mod_names; then
		failmsg="names found don't match"
		return 1
	fi
ENDT

TEST title="'LOOP find', weird file names, -exec fn"
	# Quietly skip file names unsupported by the running file system.
	numfiles=0
	for name in "normalname" \
		"name with space" \
		' weird \f\\i\\\l\\\\e\\\\\ name 1 ' \
		"${CCn}weird${CCn}file${CCn}name${CCn}2${CCn}" \
		"$tempdir/ ALL the weirdness! ${ASCIICHARS%/*}${ASCIICHARS#*/}"
	do
		v=$tempdir/$name
		{ command : > $v; } 2>/dev/null && assign weirdfile$((numfiles += 1))=$v
	done

	# Test that '-exec' can run a shell function in the main shell.
	# (Suite runs with PATH=/dev/null, so no risk of running external 'fn' on failure.)
	loop_ok=0 exec_ok=0
	fn() {
		#(shellquoteparams; printf '[DEBUG] [%s]\n' "$@"; putln _______)
		varname=$1
		shift
		for f do
			LOOP for n=1 to numfiles; DO
				assign -r v=weirdfile$n
				str eq $v $f && inc $varname
			DONE
		done
	}
	alias fn='failmsg=QUOTEFAIL && :'  # check that -exec commands are quoted, so won't resolve aliases
	LOOP find f in $tempdir -type f -exec fn exec_ok {} +; DO
		fn loop_ok $f
	DONE
	unalias fn
	isset failmsg && return 1
	if not let "loop_ok == numfiles && exec_ok == numfiles"; then
		failmsg="$numfiles != ($loop_ok; $exec_ok)"
		return 1
	fi
ENDT
