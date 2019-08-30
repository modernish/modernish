#! test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# Regression tests for var/local, as well as shell-native implementations of local variables.


# --- var/local module ---

TEST title='local globbing'
	set -- /*
	LOCAL file +o noglob; BEGIN
		set -- /*
		okmsg=$#
		failmsg=$#
		for file do
			str begin "$file" / || return
			is present "$file" || return
			#	   ^^^^^^^ must quote as globbing is active within this block
		done
		gt $# 1
	END || return
	eq $# 1
ENDT

TEST title='glob arguments'
	LOCAL file --glob -- /*; BEGIN
		okmsg=$#
		failmsg=$#
		for file do
			str begin $file / || return
			is present $file || return
			#	   ^^^^^ no quoting needed here: globbing was only applied to LOCAL args
		done
		gt $# 1
	END
ENDT


TEST title='nested local vars, opts, field splitting'
	push X Y
	X=12 Y=13
	LOCAL X=2 Y=4 +o noclobber splitthis='this string should not be subject to fieldsplitting.'; BEGIN
		set -- $splitthis
		str eq $X 2 && str eq $Y 4 && not isset -C && eq $# 1 || return
		LOCAL X=hi Y=there -o noclobber IFS=' ' splitthis='look ma, i can do local fieldsplitting!'; BEGIN
			set -- $splitthis
			str eq $X hi && str eq $Y there && isset -C && eq $# 7 || return
			X=13 Y=37
		END || return
		str eq $X 2 && str eq $Y 4 && not isset -C && eq $# 1 || return
		X=123 Y=456
	END || return
	str eq $X 12 && str eq $Y 13 && isset -C
	pop --keepstatus X Y
ENDT

TEST title='split arguments'
	LOCAL --split=: -- one:two:three; BEGIN
		str eq "$#,${1-},${2-},${3-}" "3,one,two,three"
	END
ENDT

# BUG_FNSUBSH:
# Running LOCAL in a non-forked subshell on ksh93 would cause the WRONG temporary function
# to be executed. So, running LOCAL in a non-forked subshell does not work on ksh93.
# Thankfully there is a workaround: the 'ulimit' builtin forces a fork. The workaround is
# implemented in var/local.mm; this test verifies it.
TEST title='LOCAL works in subshells'
	set -- one two three
	LOCAL; BEGIN :; END	# set dummy tmp function in case BUG_FNSUBSH workaround fails
	str eq $(LOCAL IFS +f; BEGIN PATH=$DEFPATH printf '[%s] ' "$@"; END) '[one] [two] [three] ' &&
	(LOCAL IFS='<'; BEGIN set -- "$*"; str eq "$1" "one<two<three"; END; exit "$?")
ENDT

TEST title='LEPIPEMAIN: piping into LOCAL'
	skipmsg='no LEPIPEMAIN'
	thisshellhas LEPIPEMAIN || return 3
	push result
	result=
	putln one two three four | LOCAL X IFS=$CCn; BEGIN while read X; do result="$result[$X] "; done; END
	str eq $result "[one] [two] [three] [four] "
	pop --keepstatus result
ENDT

TEST title='protection against stack corruption'
	LOCAL testvar='foo'; BEGIN
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
	END
	pop --keepstatus var3 var2 var1
	pop --keepstatus var3 var2
	pop --keepstatus var3
ENDT

TEST title="empty words after '--' are preserved"
	LOCAL --split -- '' '' 'foo bar baz' ''; BEGIN
		str eq ${#},${1-},${2-},${3-},${4-},${5-},${6-} '6,,,foo,bar,baz,'
	END
ENDT

TEST title="empty set after '--' is recognised"
	# This includes a removed empty expansion, e.g. 'LOCAL --split=$CCn -- $(pgrep foo)' with no pgrep results
	set -- one two three
	LOCAL --; BEGIN
		eq $# 0 || return 1
	END
ENDT

TEST title='--glob removes non-matching patterns'
	LOCAL IFS=, --split='!' --glob -- /dev/null/?*!!/dev/null/!/dev/null/foo!/dev/null*
	#		     ^ split by a glob character: test --split's BUG_IFS* resistance
	#	  ^ for "$*" below
	BEGIN
		failmsg="$#:$*"
		# We expect only the /dev/null* pattern to match. There is probably just
		# /dev/null, but theoretically there could be other /dev/null?* devices.
		str in ",$*," ',/dev/null,'
	END
ENDT

TEST title='LOCAL parses OK in command substitutions'
	if not (eval 'v=$(LOCAL foo; BEGIN
				putln okay
			END); str eq $v okay') 2>/dev/null
	then
		# test both BUG_ALIASCSUB workarounds: either use backticks or put a statement on the same line after BEGIN
		(eval 'v=`LOCAL foo; BEGIN
				putln okay
			END` && str eq $v okay &&
			v=$(LOCAL foo; BEGIN putln okay
			END) && str eq $v okay') \
		&& mustHave BUG_ALIASCSUB
	else
		mustNotHave BUG_ALIASCSUB
	fi
ENDT


# --- shell-native implementations of local variables ---

TEST title='native local vars: initial state'
	if not thisshellhas LOCALVARS; then
		skipmsg='no LOCALVARS'
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
ENDT

TEST title='native local vars: unsetting behaviour'
	if not thisshellhas LOCALVARS; then
		skipmsg='no LOCALVARS'
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
ENDT

TEST title='native local vars: global namesake'
	if not thisshellhas LOCALVARS; then
		skipmsg='no LOCALVARS'
		return 3
	fi
	v=global
	fooFn() {
		local v=local
		v=woops true
	}
	fooFn
	: v is ${v-UNSET}   # for xtrace
	if not isset v; then
		mustHave BUG_ASGNLOCAL
	elif not str eq $v global; then
		return 1
	else
		mustNotHave BUG_ASGNLOCAL
	fi
ENDT
