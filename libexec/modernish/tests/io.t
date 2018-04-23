#! test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# Regression tests related to file descriptors, redirection, and other I/O matters.

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

lastTest=1
