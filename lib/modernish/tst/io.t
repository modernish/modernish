#! test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# Regression tests related to file descriptors, redirection, pipelines, and other I/O matters.

TEST title='blocks can save a closed file descriptor'
	# zsh-5.0.7 displays an error when trying to close an already-closed file
	# descriptor, but the exit status is still 0, so catch stderr output.
	v=$(set +x; exec 2>&1; { :; } 4>&-)
	str empty $v || return 1
	# Now check for correct BUG_SCLOSEDFD detection
	{
		{
			while :; do
				{
					exec 4>/dev/null
				} 4>&-
				break
			done 4>&-
			# does the 4>/dev/null leak out of of both a loop and a { ...; } block?
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
ENDT 4>&-

TEST title="pipeline commands are run in subshells"
	# POSIX says at http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_12
	#	"[...] as an extension, however, any or all commands in
	#	a pipeline may be executed in the current environment."
	# Some shells execute the last element of a pipeline in the current environment (feature ID:
	# LEPIPEMAIN), but there are no currently existing shells that execute any other element of a
	# pipeline in the current environment. Scripts may break if a shell ever does. At the very least
	# it would require another modernish feature ID (e.g. ALLPIPEMAIN). Until then, this sanity check
	# should fail if that condition is ever detected.
	v1= v2= v3= v4=
	# QRK_PPIPEMAIN compat: don't use assignments in parameter substitutions, eg. : ${v1=1}
	v1=1 | v2=2 | v3=3 | v4=4
	v=$v1$v2$v3$v4
	unset -v v1 v2 v3 v4
	case $v in
	( '' )	mustNotHave LEPIPEMAIN ;;
	( 4 )	mustHave LEPIPEMAIN ;;
	(1234)	failmsg="need ALLPIPEMAIN feature ID"; return 1 ;;
	( * )	failmsg="need new shell quirk ID ($v1$v2$v3$v4)"; return 1 ;;
	esac
ENDT

TEST title='simple assignments in pipeline elements'
	unset -v v1 v2
	# LEPIPEMAIN compat: no assignment in last element
	true | v1=foo | putln "junk" | v2=bar | cat
	case ${v1-U},${v2-U} in
	( U,U )	;;
	( * )	return 1 ;;
	esac
ENDT

TEST title='param substitutions in pipeline elements'
	unset -v v1 v2
	# LEPIPEMAIN compat: no param subst in last element
	true | : ${v1=foo} | putln "junk" | : ${v2=bar} | cat
	case ${v1-U},${v2-U} in
	( U,U )	mustNotHave QRK_PPIPEMAIN ;;
	( foo,bar )
		mustHave QRK_PPIPEMAIN ;;
	( * )	return 1 ;;
	esac
ENDT

TEST title="'>>' redirection can create new file"
	{ put '' >>$tempdir/io-test5; } 2>/dev/null || return 1
ENDT

TEST title="I/O redir on func defs honoured in pipes"
	foo() {
		putln 'redir-ok' 2>/dev/null >&5
		putln 'fn-ok'
	} 5>$tempdir/io-test6
	# On bash 2.05b and 3.0, the redirection is forgotten only if the function
	# is piped through a command, so we add '| cat' to fail on this.
	case $(umask 007; foo | cat) in
	( fn-ok )
		is reg $tempdir/io-test6 && read v <$tempdir/io-test6 && str eq $v 'redir-ok' || return 1 ;;
	( * )	return 1 ;;
	esac
ENDT

TEST title='globbing works regardless of IFS'
	push -o noglob IFS
	set +o noglob
	IFS=$ASCIICHARS
	set -- /d?*
	IFS=	# BUG_IFSGLOBC compat: eliminate glob chars from IFS before popping
	pop -o noglob IFS
	for v do
		if str eq $v /dev; then
			mustNotHave BUG_IFSGLOBP
			return
		fi
	done
	mustHave BUG_IFSGLOBP
ENDT

TEST title="'<>' redirection defaults to stdin"
	(umask 077; putln ok >$tempdir/io-test8)
	read v </dev/null <>$tempdir/io-test8
	case $v in
	( ok )	mustNotHave BUG_REDIRIO ;;
	( '' )	mustHave BUG_REDIRIO ;;
	( * )	return 1 ;;
	esac
ENDT

TEST title='redirs and assignments can be alternated'
	# use 'eval' to delay parse error on zsh 5.0.x
	(umask 077; eval 'v=1 >$tempdir/iotest9 v=2 2>&2 v=3 3>/dev/null v=4 putln ok' 2>/dev/null)
	if ne $? 0; then
		mustHave BUG_REDIRPOS
		return
	fi
	read v <$tempdir/iotest9
	str eq $v ok || mustHave BUG_REDIRPOS
ENDT

TEST title='comsubs work with stdout closed outside'
	{
		v=$(putln foo 5>/dev/null; command -v break; putln bar)
	} >&-
	case $v in
	( 'break' )
		# test that the documented BUG_CSUBSTDO workaround works
		{
			v=$(: 1>&1; putln foo 5>/dev/null; command -v break; putln bar)
		} >&-
		case $v in
		( foo${CCn}break${CCn}bar )
			mustHave BUG_CSUBSTDO ;;
		( * )	return 1 ;;
		esac ;;
	( "foo${CCn}break${CCn}bar" )
		mustNotHave BUG_CSUBSTDO ;;
	( * )	return 1 ;;
	esac
ENDT

TEST title='comsubs correctly strip final linefeeds'
	v=${CCn}one$CCn$CCn$CCn`
		false && putln nothing
	`$CCn$CCn${CCn}two$CCn$CCn$CCn$(
		true && putln something
	)${CCn}three$CCn$CCn$CCn$CCn$CCn$(
		:
	)$CCn$CCn$CCn
	case $v in
	( ${CCn}one$CCn$CCn$CCn$CCn$CCn${CCn}two$CCn$CCn${CCn}something${CCn}three$CCn$CCn$CCn$CCn$CCn$CCn$CCn$CCn )
		mustNotHave BUG_CSUBRMLF ;;
	( ${CCn}one$CCn$CCn${CCn}two$CCn$CCn${CCn}something${CCn}three$CCn$CCn$CCn )
		mustHave BUG_CSUBRMLF ;;
	( * )	return 1 ;;
	esac
ENDT

TEST title='comsubs strip final linefeeds (here-doc)'
	v=$(
		thisshellhas BUG_HDOCMASK && umask 077
		cat <<-end_of_heredoc

		one


		$(false && putln nothing)


		two


		$(true && putln something)
		three




		` : `

		x
		end_of_heredoc
	)
	case $v in
	( ${CCn}one$CCn$CCn$CCn$CCn$CCn${CCn}two$CCn$CCn${CCn}something${CCn}three$CCn$CCn$CCn$CCn$CCn$CCn${CCn}x )
		mustNotHave BUG_CSUBRMLF ;;
	( ${CCn}one$CCn$CCn${CCn}two$CCn$CCn${CCn}something${CCn}three$CCn${CCn}x )
		mustHave BUG_CSUBRMLF ;;
	( * )	return 1 ;;
	esac
ENDT

TEST title='backtick comsub can nest double quotes'
	failmsg=$(set +x 1>&1   # workaround for segfault on ksh 93u+ 2012-08-01 -- redirection triggers fork
		eval 'true "`true -E "^Exec(\[[^]=]*])?=" "$file" | true -d= -f 2- | true`"' 2>&1)
	case $? in
	0)	mustNotHave BUG_CSUBBTQUOT ;;
	*)	mustHave BUG_CSUBBTQUOT ;;
	esac
ENDT

TEST title='line continuation works in comsub'
	{ v=$(pu\
tln it i\
s ok); } 2>/dev/null
	case $v in
	( it${CCn}is${CCn}ok )
		mustNotHave BUG_CSUBLNCONT ;;
	( '' )	mustHave BUG_CSUBLNCONT ;;
	( * )	failmsg=$v; return 1 ;;
	esac
ENDT

TEST title="put/putln check I/O with SIGPIPE ignored"
	v=$(
		set +x
		{
			(
				command trap "" PIPE
				v=0
				while let "(v += 1) < 250"; do
					putln	pppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp \
						pppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp \
						pppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp \
						pppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp || exit
				done 2>/dev/null
				putln BUG >&2
			) | true   # pipe into cmd that does not read input; I/O error should occur when pipe buffer is full
		} 2>&1
	)
	case $v in
	( BUG )	mustHave BUG_PUTIOERR ;;
	( '' )	mustNotHave BUG_PUTIOERR ;;
	( * )	shellquote -f failmsg=$v; return 1 ;;
	esac
ENDT

TEST title="error in function call redirection"
	testfn() {
		true
	}
	exec 3>&-
	(testfn >&3; exit 37) 2>/dev/null
	e=$?
	unset -f testfn
	case $e in
	( 37 )	mustNotHave QRK_FNRDREXIT ;;
	( 0 | ??* )
		failmsg=$e
		return 1 ;;
	( * )	mustHave QRK_FNRDREXIT ;;
	esac
ENDT
