#! test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# Sanity checks to verify correct modernish initialisation.

TEST title='availability of POSIX utils in $DEFPATH'
	# Modernish and its main modules depend on these POSIX utilities
	# to be installed in $(getconf PATH).
	# TODO: periodically update
	for cmd in \
		[ \
		awk \
		bc \
		cat \
		cut \
		dd \
		echo \
		expr \
		fold \
		grep \
		iconv \
		id \
		kill \
		ls \
		mkdir \
		paste \
		pr \
		printf \
		ps \
		rm \
		sed \
		sh \
		sort \
		stty \
		test \
		tput \
		tr \
		wc
	do
		IFS=':'; for p in $DEFPATH; do IFS=
			can exec $p/$cmd && continue 2
		done
		warnmsg=${warnmsg:+${warnmsg}, }\'$cmd\'
	done
	if isset warnmsg; then
		if eq opt_q 2; then
			# We warn rather than (x)fail because it's not a bug in modernish or the shell. However,
			# if we're testing in extra-quiet mode, we might be running from install.sh. Warnings
			# are not displayed, but we still really want to warn the user about missing utilities.
			str in $warnmsg ',' && v=utilities || v=utility
			putln "  ${tBold}WARNING:${tReset} Standard $v missing in $DEFPATH: ${tRed}${warnmsg}${tReset}"
		fi
		warnmsg="missing: $warnmsg"
		return 4
	fi
ENDT

TEST title='ASCII chars and control char constants'
	# Test the correctness of $CC01..$CC1F,$CC7F (which are all concatenated in $CONTROLCHARS). These
	# are initialised quickly by including their control character values directly in bin/modernish.
	# Most editors handle this gracefully, but check here that no corruption has occurred.
	# Include all the other ASCII characters in the test as well while we're at it;
	# $ASCIICHARS starts with $CONTROLCHARS.
	case $ASCIICHARS in
	( $'\1\2\3\4\5\6\a\b\t\n\v\f\r\16\17\20\21\22\23\24\25\26\27\30\31\32\e\34\35\36\37\177 "#$&'\
\'$'()*;<>?[\\\\\\]`{|}~0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz%+,./:=@_^!-' )
		# escaping a ' like use $'foo\'bar' causes syntax error on shells without CESCQUOT; use $'foo'\'$'bar'.
		mustHave CESCQUOT ;;
	( $'\1\2\3\4\5\6\a\b\t\n\v\f\r\16\17\20\21\22\23\24\25\26\27\30\31\32\33\34\35\36\37\177 "#$&'\
\'$'()*;<>?[\\\\\\]`{|}~0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz%+,./:=@_^!-' )
		# busybox ash with "bash compatibility" compiled in has CESCQUOT without \e.
		mustHave CESCQUOT && okmsg="$okmsg (no \\e)" ;;
	( "$(PATH=$DEFPATH command printf \
	   '\1\2\3\4\5\6\a\b\t\n\v\f\r\16\17\20\21\22\23\24\25\26\27\30\31\32\33\34\35\36\37\177 "#$&'\
\''()*;<>?[\\\\\\]`{|}~0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz%%+,./:=@_^!-')" )		# "
		# note that CESCQUOT supports \e, but POSIX printf(1) doesn't
		# and that the % must be doubled on printf.
		str eq $'a' '$a' && mustNotHave CESCQUOT ;;
	( * )	return 1 ;;
	esac
ENDT

TEST title='check for fatal bug/quirk combinations'
	# Modernish currently does not cope well with these combinations of shell bugs and quirks.
	# No supported shell is known to have both, so we don't have the necessary workarounds. But
	# it's worth checking here, as these combinations could occur in the future. If they ever
	# do, the comments below should help search the code for problems in need of a workaround.

	if thisshellhas NONFORKSUBSH && ! (eval ': ${.sh.subshell}') 2>/dev/null; then
		failmsg="${failmsg:+${failmsg}; }NONFORKSUBSH on non-ksh93"
	fi

	if thisshellhas BUG_FNSUBSH && ! (eval ': ${.sh.subshell}') 2>/dev/null; then
		failmsg="${failmsg:+${failmsg}; }BUG_FNSUBSH on non-ksh93"
	fi

	if thisshellhas BUG_FNSUBSH QRK_EXECFNBI; then
		# If we cannot unset a shell function (e.g. hardened 'mkdir') within a subshell,
		# *and* we're trying to 'exec mkdir' from a subshell while bypassing that shell
		# function, with this combination that would be impossible. The only workarounds left
		# would be to pre-determine and store the absolute path and then 'exec' that, or to
		# abandon the use of 'exec' and put up with forking unnecessary extra processes.
		failmsg="${failmsg:+${failmsg}; }BUG_FNSUBSH+QRK_EXECFNBI"
	fi

	if thisshellhas ROFUNC QRK_EXECFNBI; then
		# Similar as above. If a function is set to read-only, we can't unset it in a
		# subshell to work around QRK_EXECFNBI.
		failmsg="${failmsg:+${failmsg}; }ROFUNC+QRK_EXECFNBI"
	fi

	if thisshellhas BUG_SETOUTVAR \
	&& ! { thisshellhas -o posix && (set +o posix; command typeset -g) >/dev/null 2>&1; }
	then
		# On yash with BUG_SETOUTVAR, we need to be able to switch off POSIX mode
		# and use 'typeset -g' to work around the lack of 'set' to print variables.
		failmsg="${failmsg:+${failmsg}; }BUG_SETOUTVAR w/o 'typeset -g'"
	fi

	if thisshellhas BUG_TRAPSUB0 && not (readonly foo; command unset foo 2>/dev/null || exit 0); then
		# On dash and yash, we need to test 'isset -r var' by trying to unset the variable
		# using 'command readonly var=' in a subshell, and then, as a BUG_TRAPSUB0 workaround,
		# doing an explicit 'exit' command to pass down the result from the subshell. One variant of
		# BUG_CMDSPEXIT would cause the subshell to exit immediately on failure of 'command unset',
		# so it would never reach the explicit 'exit' command, defeating the BUG_TRAPSUB0 workaround.
		failmsg="${failmsg:+${failmsg}; }BUG_TRAPSUB0+BUG_CMDSPEXIT"
	fi

	# TODO: think of other fatal shell bug/quirk combinations and add them above

	not isset failmsg
ENDT

TEST title="'unset' quietly accepts nonexistent item"
	# for zsh, we set a wrapper unset() for this in bin/modernish
	# so that 'unset -f foo' stops complaining if there is no foo().
	unset -v _Msh_nonexistent_variable &&
	unset -f _Msh_nonexistent_function ||
	return 1
ENDT

TEST title="SIGPIPE exit status correctly detected"
	$MSH_SHELL -c 'kill -s PIPE $$'
	case $? in
	( $SIGPIPESTATUS )
		mustNotHave WRN_NOSIGPIPE && okmsg=$SIGPIPESTATUS ;;
	( 0 )	mustHave WRN_NOSIGPIPE
		eq $? 4 && eq SIGPIPESTATUS 99999 && return 4 ;;
	( * )	return 1 ;;
	esac
ENDT

TEST title="'exec' exports preceding var assignments"
	# POSIX leaves it unspecified whether 'exec' exports variable assinments preceding
	# it but modernish relies on this feature as all currently supported shells have it.
	case $(unset -v v; v=foo PATH=$DEFPATH exec "$MSH_SHELL" -c 'echo "${v-U}"') in
	( foo )	;;
	( U )	return 1 ;;
	( * )	failmsg='weird result'; return 1 ;;
	esac
ENDT

TEST title="minimum XSI signal numbers available"
	# Ref.: http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_28_03
	thisshellhas --sig=1  && str eq $REPLY HUP  || xfailmsg=${xfailmsg-no }${xfailmsg+, }1/HUP
	thisshellhas --sig=2  && str eq $REPLY INT  || xfailmsg=${xfailmsg-no }${xfailmsg+, }2/INT
	thisshellhas --sig=3  && str eq $REPLY QUIT || xfailmsg=${xfailmsg-no }${xfailmsg+, }3/QUIT
	thisshellhas --sig=6  && str eq $REPLY ABRT || xfailmsg=${xfailmsg-no }${xfailmsg+, }6/ABRT
	thisshellhas --sig=9  && str eq $REPLY KILL || xfailmsg=${xfailmsg-no }${xfailmsg+, }9/KILL
	thisshellhas --sig=14 && str eq $REPLY ALRM || xfailmsg=${xfailmsg-no }${xfailmsg+, }14/ALRM
	thisshellhas --sig=15 && str eq $REPLY TERM || xfailmsg=${xfailmsg-no }${xfailmsg+, }15/TERM
	not isset xfailmsg || return 2
ENDT
