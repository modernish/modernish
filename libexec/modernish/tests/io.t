#! test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# Regression tests related to file descriptors, redirection, pipelines, and other I/O matters.

doTest1() {
	title='blocks can save a closed file descriptor'
	{
		{
			while :; do
				{
					exec 4>/dev/tty
				} 4>&-
				break
			done 4>&-
			# does the 4>/dev/tty leak out of of both a loop and a { ...; } block?
			if { true >&4; } 2>/dev/null; then
				mustHave BUG_SCLOSEDFD
			else
				mustNotHave BUG_SCLOSEDFD
			fi
		} 4>&-
	} 4>/dev/null	# BUG_SCLOSEDFD workaround
	if eq $? 1 || { true >&4; } 2>/dev/null; then
		return 1
	elif isset xfailmsg; then
		return 2
	fi
} 4>&-

doTest2() {
	title="pipeline commands are run in subshells"
	# POSIX says at http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_12
	#	"[...] as an extension, however, any or all commands in
	#	a pipeline may be executed in the current environment."
	# Some shells execute the last element of a pipeline in the current environment (feature ID:
	# LEPIPEMAIN), but there are no currently existing shells that execute any other element of a
	# pipeline in the current environment. Scripts may break if a shell ever does. At the very least
	# it would require another modernish feature ID (e.g. ALLPIPEMAIN). Until then, this sanity check
	# should fail if that condition is ever detected.
	v1= v2= v3= v4=
	# QRK_APIPEMAIN compat: use assignment-arguments, not real assignments
	# QRK_PPIPEMAIN compat: don't use assignments in parameter substitutions, eg. : ${v1=1}
	unexport v1=1 | unexport v2=2 | unexport v3=3 | unexport v4=4
	case $v1$v2$v3$v4 in
	( '' )	mustNotHave LEPIPEMAIN ;;
	( 4 )	mustHave LEPIPEMAIN ;;
	(1234)	failmsg="need ALLPIPEMAIN feature ID"; return 1 ;;
	( * )	failmsg="need new shell quirk ID ($v1$v2$v3$v4)"; return 1 ;;
	esac
}

doTest3() {
	title='simple assignments in pipeline elements'
	unset -v v1 v2
	# LEPIPEMAIN compat: no assignment in last element
	true | v1=foo | putln "junk" | v2=bar | cat
	case ${v1-U},${v2-U} in
	( U,U )	mustNotHave QRK_APIPEMAIN ;;
	( foo,bar )
		mustHave QRK_APIPEMAIN ;;
	( * )	return 1 ;;
	esac
}

doTest4() {
	title='param substitutions in pipeline elements'
	unset -v v1 v2
	# LEPIPEMAIN compat: no param subst in last element
	true | : ${v1=foo} | putln "junk" | : ${v2=bar} | cat
	case ${v1-U},${v2-U} in
	( U,U )	mustNotHave QRK_PPIPEMAIN ;;
	( foo,bar )
		mustHave QRK_PPIPEMAIN ;;
	( * )	return 1 ;;
	esac
}

doTest5() {
	title="'>>' redirection can create new file"
	{ put '' >>$testdir/io-test5; } 2>/dev/null && mustNotHave BUG_APPENDC || mustHave BUG_APPENDC
}

doTest6() {
	title="I/O redir on func defs honoured in pipes"
	testFn() {
		putln 'redir-ok' >&5
		putln 'fn-ok'
	} 5>$testdir/io-test6
	case $(umask 007; testFn | cat) in
	( fn-ok )
		if is reg $testdir/io-test6 && read v <$testdir/io-test6 && identic $v 'redir-ok'; then
			mustNotHave BUG_FNREDIRP
		else
			mustHave BUG_FNREDIRP
		fi ;;
	( * )	return 1 ;;
	esac
}

doTest7() {
	title='globbing works regardless of IFS'
	push -o noglob IFS
	set +o noglob
	IFS=$ASCIICHARS
	set -- /d?*
	IFS=	# BUG_IFSGLOBC compat: eliminate glob chars from IFS before popping
	pop -o noglob IFS
	for v do
		if identic $v /dev; then
			mustNotHave BUG_IFSGLOBP
			return
		fi
	done
	mustHave BUG_IFSGLOBP
}

doTest8() {
	title="'<>' redirection defaults to stdin"
	(umask 077; putln ok >$testdir/io-test8)
	read v </dev/null <>$testdir/io-test8
	case $v in
	( ok )	mustNotHave BUG_REDIRIO ;;
	( '' )	mustHave BUG_REDIRIO ;;
	( * )	return 1 ;;
	esac
}

doTest9() {
	title='redirs and assignments can be alternated'
	# use 'eval' to delay parse error on zsh 5.0.x
	(umask 077; eval 'v=1 >$testdir/iotest9 v=2 2>&2 v=3 3>/dev/null v=4 putln ok' 2>/dev/null)
	if ne $? 0; then
		mustHave BUG_REDIRPOS
		return
	fi
	read v <$testdir/iotest9
	identic $v ok || mustHave BUG_REDIRPOS
}

lastTest=9
