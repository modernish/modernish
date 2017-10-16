#! test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# Sanity checks to verify correct modernish initialisation.

doTest1() {
	title='availability of POSIX utils in $DEFPATH'
	# Modernish and its main modules depend on these POSIX utilities
	# to be installed in $(getconf PATH).
	# TODO: periodically update
	push PATH cmd
	PATH=$DEFPATH
	for cmd in \
		[ \
		awk \
		bc \
		cat \
		dd \
		echo \
		expr \
		fold \
		grep \
		id \
		kill \
		ls \
		mkdir \
		paste \
		printf \
		ps \
		rm \
		sed \
		sh \
		sort \
		test \
		tput \
		tr \
		wc
	do
		command -v $cmd || xfailmsg=${xfailmsg-missing: }${xfailmsg+, }$cmd
	done
	pop PATH cmd
	if isset xfailmsg; then
		return 2
	fi
} >/dev/null

doTest2() {
	title='control character constants'
	# These are now initialised quickly by including their control
	# character values directly in bin/modernish. Most editors handle
	# this gracefully, but check here that no corruption has occurred by
	# comparing it with 'printf' output.
	# The following implicitly tests the correctness of $CC01..$CC1F,$CC7F
	# as well, because these are all concatenated in $CONTROLCHARS.
	identic $CONTROLCHARS \
		$(PATH=$DEFPATH command printf \
			'\1\2\3\4\5\6\7\10\11\12\13\14\15\16\17\20\21\22\23\24\25\26\27\30\31\32\33\34\35\36\37\177')
}

doTest3() {
	title="'unset' quietly accepts nonexistent item"
	# for zsh, we set a wrapper unset() for this in bin/modernish
	# so that 'unset -f foo' stops complaining if there is no foo().
	unset -v _Msh_nonexistent_variable &&
	unset -f _Msh_nonexistent_function ||
	return 1
}

doTest4() {
	title='shell arithmetic supports octal'
	xfailmsg='BUG_NOOCTAL'
	case $((014+032)) in
	( 38 )	return 0 ;;
	( 46 )	thisshellhas BUG_NOOCTAL && return 2 ;;
	esac
	return 1
}

lastTest=4
