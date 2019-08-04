#! test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# Regression tests related to (built-in) utilities of the shell.

TEST title="options to 'command' can be expansions"
	v='-v'
	MSH_NOT_FOUND_OK=1
	command $v : >/dev/null 2>&1
	v=$?
	unset -v MSH_NOT_FOUND_OK
	case $v in
	( 0 )	mustNotHave BUG_CMDOPTEXP ;;
	# test suite runs with PATH=/dev/null, so we can rely on 127 = not found
	( 127 )	mustHave BUG_CMDOPTEXP ;;
	( * )	return 1 ;;
	esac
ENDT

TEST title="'command' parses arguments properly"
	# FTL_COMMAND2P: double evaluation of grammar and/or parameter
	# expansion grammar when using 'command' with an external command.
	# (AT&T ksh88; schilytools sh <= 2017-08-14)
	unset -v v
	command /dev/null \${v=x} 2>/dev/null
	not isset v
ENDT

TEST title="'command -v -p' searches default PATH"
	command -v -p chmod >/dev/null 2>&1 \
	&& command -v -p : >/dev/null
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
ENDT

TEST title="'command' stops special builtins exiting"
	v=$(	readonly v=foo
		exec 2>/dev/null
		# All the "special builtins" below should fail, and not exit, so 'putln ok' is reached.
		# Ref.: http://pubs.opengroup.org/onlinepubs/9699919799/utilities/contents.html
		# Left out are 'command exec /dev/null/nonexistent', where no shell follows the standard,
		# 'command eval "("', where too many shells either exit on syntax error or become crash-prone,
		# as well as 'command exit' and 'command return', because, well, obviously.
		command : </dev/null/nonexistent	&& put BAD01
		command . /dev/null/nonexistent		&& put BAD02
		command export v=baz			&& put BAD03
		command readonly v=bar			&& put BAD04
		command set +o bad@option		&& put BAD05
		command shift $(($# + 1))		&& put BAD06
		command times foo bar >/dev/null	# many shells don't check for no arguments here; oh well
		command trap foo bar baz quux		&& put BAD08
		command unset v				&& put BAD09
		if not thisshellhas QRK_BCDANGER; then
			command break			# 'break' and 'continue' are POSIXly allowed to quietly...
			command continue		# ..."succeed" if they are used outside of a loop :-/
		fi
		putln ok)
	case $v in
	( ok )	mustNotHave BUG_CMDSPEXIT ;;
	( '' )	mustHave BUG_CMDSPEXIT ;;
	( * )	failmsg=$v; return 1 ;;
	esac
ENDT

TEST title="'command -v' finds reserved words"
	v=$(command -v until)
	case $v in
	( until )
		;;
	( * )	return 1 ;;
	esac
ENDT

TEST title="'break' works from within 'eval'"
	(
		for v in 0 1 2; do
			eval "v=OK${CCn}break${CCn}v=FreeBSDvariant" 2>/dev/null
			exit 13
		done
		str eq $v OK && exit 42
	)
	case $? in
	( 42 )	mustNotHave BUG_EVALCOBR ;;
	( * )	mustHave BUG_EVALCOBR ;;
	esac
ENDT

TEST title="'continue' works from within 'eval'"
	(
		for e in 1 2 42; do
			eval "v=OK${CCn}continue${CCn}v=FreeBSDvariant" 2>/dev/null
			break
		done
		str eq $v OK && exit $e
	)
	case $? in
	( 42 )	mustNotHave BUG_EVALCOBR ;;
	( * )	mustHave BUG_EVALCOBR ;;
	esac
ENDT

TEST title="\$LINENO works from within 'eval'"
	if not thisshellhas LINENO; then
		skipmsg='no LINENO'
		return 3
	fi
	v=$LINENO; eval "${CCn}x=\$LINENO${CCn}y=\$LINENO${CCn}z=\$LINENO${CCn}"
	if let "y == x + 1 && z == y + 1"; then
		mustNotHave BUG_LNNOEVAL
	elif let "x == v && y == v && z == v"; then
		mustNotHave BUG_LNNOEVAL && okmsg='no increment'
	elif let "x == 0 && y == 0 && z == 0"; then
		mustHave BUG_LNNOEVAL
	else
		failmsg="x==$x; y==$y; z==$z"
		return 1
	fi
ENDT

TEST title="\$LINENO works within alias expansion"
	if not thisshellhas LINENO; then
		skipmsg='no LINENO'
		return 3
	fi
	alias _util_test8="${CCn}x=\$LINENO${CCn}y=\$LINENO${CCn}z=\$LINENO${CCn}"
	# use 'eval' to force immediate alias expansion in function definition
	eval 'foo() {
		_util_test8
	}'
	foo
	unalias _util_test8
	unset -f foo
	if let "y == x + 1 && z == y + 1"; then
		mustNotHave BUG_LNNOALIAS
	elif let "x == 0 && y == 0 && z == 0"; then
		mustHave BUG_LNNOALIAS
	elif let "y == x && z == y"; then
		mustNotHave BUG_LNNOALIAS && okmsg='no increment'
	else
		failmsg="x==$x; y==$y; z==$z"
		return 1
	fi
ENDT

TEST title="'export' can export readonly variables"
	v=$(
		msh_util_test9=ok
		readonly msh_util_test9
		export msh_util_test9 2>/dev/null
		set +x
		PATH=$DEFPATH $MSH_SHELL -c 'echo "$msh_util_test9"' 2>&1
	)
	case $v in
	( ok )	mustNotHave BUG_NOEXPRO ;;
	( '' )	mustHave BUG_NOEXPRO ;;
	( * )	return 1 ;;
	esac
ENDT

TEST title="shell options w/o ltrs don't affect \${-}"
	if not thisshellhas -o nolog; then
		skipmsg='no nolog option'
		return 3
	fi
	(
		set -C -o nolog
		v=abc${-}def${-}ghi
		set +o nolog
		str eq $v abc$-def$-ghi
	) || mustHave BUG_OPTNOLOG
ENDT

TEST title="long option names case-insensitive?"
	if thisshellhas BUG_CMDSPEXIT; then
		(set +o nOgLoB +o NoUnSeT +o nOcLoBbEr) 2>/dev/null
	else
		push -o nOgLoB -o NoUnSeT -o nOcLoBbEr
		command set +o nOgLoB +o NoUnSeT +o nOcLoBbEr 2>/dev/null
		pop --keepstatus -o nOgLoB -o NoUnSeT -o nOcLoBbEr
	fi
	case $? in
	( 0 )	mustHave QRK_OPTCASE && okmsg="yes ($okmsg)" ;;
	( * )	mustNotHave QRK_OPTCASE && okmsg="no" ;;
	esac
ENDT

TEST title="long option names insensitive to '_'?"
	if thisshellhas BUG_CMDSPEXIT; then
		(set +o nog_lob +o no_un__s_e__t +o nocl___obbe_r) 2>/dev/null
	else
		push -o nog_lob -o no_un__s_e__t -o nocl___obbe_r
		command set +o nog_lob +o no_un__s_e__t +o nocl___obbe_r 2>/dev/null
		pop --keepstatus -o nog_lob -o no_un__s_e__t -o nocl___obbe_r
	fi
	case $? in
	( 0 )	mustHave QRK_OPTULINE && okmsg="yes ($okmsg)" ;;
	( * )	mustNotHave QRK_OPTULINE && okmsg="no" ;;
	esac
ENDT

TEST title="long option names insensitive to '-'?"
	if thisshellhas BUG_CMDSPEXIT; then
		(set +o nog-lob +o no-un--s-e--t +o nocl---obbe-r) 2>/dev/null
	else
		push -o nog-lob -o no-un--s-e--t -o nocl---obbe-r
		command set +o nog-lob +o no-un--s-e--t +o nocl---obbe-r 2>/dev/null
		pop --keepstatus -o nog-lob -o no-un--s-e--t -o nocl---obbe-r
	fi
	case $? in
	( 0 )	mustHave QRK_OPTDASH && okmsg="yes ($okmsg)" ;;
	( * )	mustNotHave QRK_OPTDASH && okmsg="no" ;;
	esac
ENDT

TEST title="long options have dynamic 'no' prefix?"
	if (set +o nonotify +o noallexport -o exec -o glob -o noerrexit) 2>/dev/null; then
		mustHave QRK_OPTNOPRFX && okmsg="yes ($okmsg)"
	else
		mustNotHave QRK_OPTNOPRFX && okmsg="no"
	fi
ENDT

TEST title="long option names can be abbreviated?"
	push -o ignoreeof
	if pop -o ignoreeo; then
		mustHave QRK_OPTABBR && okmsg="yes ($okmsg)"
	else
		pop -o ignoreeof || return 1
		mustNotHave QRK_OPTABBR && okmsg="no"
	fi
ENDT

TEST title="'set' in function outputs global vars"
	thisshellhas LOCALVARS && local foo=BUG_SETOUTVAR
	v=$(set)
	case $v in
	( testscript=* | *${CCn}testscript=* )
		mustNotHave BUG_SETOUTVAR ;;
	( foo=*BUG_SETOUTVAR* )
		thisshellhas LOCALVARS && mustHave BUG_SETOUTVAR ;;
	( '' )	not thisshellhas LOCALVARS && mustHave BUG_SETOUTVAR ;;
	( * )	return 1 ;;
	esac
ENDT

TEST title="'command exec' fails without exiting"
	# check correct BUG_CMDEXEC detection
	(
		thisshellhas BUG_FNSUBSH && ulimit -t unlimited  # ksh93 compat: fork this subshell
		fn() {
			command exec 5>&6 || command exec 1>&1
		}
		# Another effect of BUG_CMDEXEC is that an explicit 'exit'
		# makes the subshell hang, so avoid that and use 'setstatus'.
		if ! fn one two three 2>/dev/null 5>&- 6>&-; then
			setstatus 112
		elif str eq $#,${1-},${2-},${3-} 3,one,two,three; then
			setstatus 111
		elif ne $# 0; then
			setstatus 113
		fi
	)
	case $? in
	( 0 )	mustNotHave BUG_CMDEXEC ;;
	( 111 )	mustHave BUG_CMDEXEC ;;
	( 112 )	failmsg=FNFAIL; return 1 ;;
	( 113 )	failmsg=PPFAIL; return 1 ;;
	( * )	return 1 ;;
	esac
ENDT

TEST title="'command .' fails without exiting"
	# On dash < 0.5.7, trying to launch a nonexistent command from a dot script sourced with 'command .' causes program
	# flow corruption. The nonexistent command causes it to return from the dot script with a nonzero exit status (so
	# 'putln COR' is executed), then it continues where it left off in the dot script (executing 'putln end').
	# Also, triggering the bug makes the shell very likely to hang, so test it in a subshell (command substitution).
	v=$(	umask 022 &&
		putln >$testdir/command_dot.sh '/dev/null/ne 2>/dev/null' 'putln end' &&
		MSH_NOT_FOUND_OK=y
		command . "$testdir/command_dot.sh" || putln COR )
	case $v in
	( end )	;;
	( COR${CCn}end )  # dash < 0.5.7
		failmsg="flow corrupt"; return 1 ;;
	( '' )	# No known variant of BUG_CMDSPEXIT causes 'command .' to exit on failure.
		failmsg="exits"; return 1 ;;
	( * )	shellquote v; failmsg="new bug: $v"; return 1 ;;
	esac
ENDT

TEST title="'command -v' is quiet on not found"
	# This fails on bash < 3.1.0.
	v=$(set +x
	    command -v /dev/null/nonexistent 2>&1)
	str empty $v
ENDT

TEST title="getopts val for no opt-arg (errmsg mode)"
	thisshellhas LOCALVARS && local OPTIND
	OPTIND=1 v=
	set -- -xfoo -yz
	while getopts x:yz: opt >/dev/null 2>&1; do
		v="${v:+$v/}$opt,${OPTARG:-Empty}"
	done
	case $v in
	( "x,foo/y,Empty/?,Empty" )
		mustNotHave BUG_GETOPTSMA ;;
	( "x,foo/y,Empty/:,Empty" )
		mustHave BUG_GETOPTSMA ;;
	( * )	return 1 ;;
	esac
ENDT

TEST title="getopts val for no opt-arg (quiet mode)"
	thisshellhas LOCALVARS && local OPTIND
	OPTIND=1 v=
	set -- -xfoo -yz
	while getopts :x:yz: opt; do
		v="${v:+$v/}$opt,${OPTARG:-Empty}"
	done
	case $v in
	( "x,foo/y,Empty/:,z" )
		;;
	( * )	return 1 ;;
	esac
ENDT

TEST title="'unset' unexports an unset variable"
	unset -v a_good_test_var
	export a_good_test_var
	unset -v a_good_test_var  # unexport?
	case $(export -p)${CCn} in
	( *\ a_good_test_var[${CCn}=]* )
		mustHave BUG_UNSETUNXP ;;
	( * )	mustNotHave BUG_UNSETUNXP ;;
	esac
ENDT

TEST title="'command set --' sets the PPs"
	set -- 'one'
	push -o noglob
	set +o noglob
	command set -- $MSH_MDL/*.mm
	pop -o noglob
	if let "$# == 1" && str eq "$1" 'one'; then
		mustHave BUG_CMDSETPP
		return
	fi
	countfiles -s $MSH_MDL '*.mm'
	failmsg='wrong number'
	let "REPLY == $#" || return 1
ENDT
