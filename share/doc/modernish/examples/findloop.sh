#! /usr/bin/env modernish
#! use safe -k
#! use sys/dir/countfiles
#! use var/arith/cmp
#! use var/loop

# Example of an interactive 'find' loop.
# See the LICENSE file in the main modernish directory for the licence.
#
# 'LOOP find' supports the full expression language of your local 'find' utility plus its own
# additions. If you're curious how 'LOOP find' invokes the 'find' utility, export _loop_DEBUG=y
# to show each utility command line as it is executed, with all modernish features translated.
#
# Some notes regarding 'LOOP find' expressions in modernish:
#
# * -and and -a are the same, -or and -o are the same, -not and ! are the same. Modernish makes
#   the long/readable versions portable for 'LOOP find' on all systems, not only BSD and GNU.
#   It also translates some other useful GNU/BSD-isms. See the documentation for details.
#
# * -and/-a is optional -- that is, '-prim1 -prim2' is the same as 'prim1 -and -prim2'.
#   Whether implied or explicitly given, -and has a higher precedence than -or, so that
#   '-prim1 -or -prim2 -and -prim3' is the same as '-prim1 -or \( -prim2 -and -prim3 \)'.
#
# * If -iterate is not given, any given expression is enclosed in implicit parentheses and
#   -iterate is appended. This is the same behaviour as with -print on standard 'find'.
#
# * The -iterate primary (being implemented as an external process -exec'ed by the 'find'
#   utility) normally optimises overall performance by internally saving up groups of 'find'
#   results before rapidly iterating the loop once per file. But if the -ask (or -ok or
#   -okdir) primary is used, and '--xargs' is not used, and standard input is on a terminal,
#   then any subsequent -iterate has that optimisation disabled, so that loop processing
#   and/or output is not delayed by this internal grouping and the user immediately sees the
#   results of each confirmation. HOWEVER, that behaviour change is local to the current set
#   of \( parentheses \) and the optimisation is restored upon leaving them. To see what this
#   means in action, replace the 'LOOP find' expression below with the following:
#	LOOP find file in ${1:-$HOME} \
#		-type d -and \( -ask 'Traverse directory "{}"?' -or -prune \) \
#		-or -iterate

LOOP find file in ${1:-$HOME} \
	-type d -and -not -ask 'Traverse directory "{}"?' -and -prune \
	-or -iterate
DO
	shellquote -f quotedfnam=$file
	if is reg $file; then
		putln "$quotedfnam is a regular file"
	elif is dir $file; then
		if not can read $file; then putln "$quotedfnam is a directory in which you don't have read permission"
		elif countfiles -s $file; gt REPLY 0; then putln "$quotedfnam is a directory with $REPLY files"
		else putln "$quotedfnam is an empty directory"
		fi
	elif is sym $file; then
		if not is -L present $file; then putln "$quotedfnam is a symlink to a nonexistent file"
		elif is -L dir $file; then
			countfiles -s $file
			if gt REPLY 0; then putln "$quotedfnam is a symlink to a directory with $REPLY files"
			else putln "$quotedfnam is a symlink to an empty directory"
			fi
		elif is -L reg $file; then putln "$quotedfnam is a symlink to a regular file"
		elif is -L dir $file; then putln "$quotedfnam is a symlnk to a directory"
		elif is -L fifo $file; then putln "$quotedfnam is a symlink to a named pipe"
		elif is -L socket $file; then putln "$quotedfnam is a symlink to a socket"
		elif is -L blockspecial $file; then putln "$quotedfnam is a symlink to a block special device"
		elif is -L charspecial $file; then putln "$quotedfnam is a symlink to a character special device"
		else	put "$quotedfnam: symlink to UNKNOWN FILE TYPE. File system error? 'ls -ld' says: "
			ls -ld $file 2>&1
		fi
	elif is fifo $file; then putln "$quotedfnam is a named pipe"
	elif is socket $file; then putln "$quotedfnam is a socket"
	elif is blockspecial $file; then putln "$quotedfnam is a block special device"
	elif is charspecial $file; then putln "$quotedfnam is a character special device"
	else	put "$quotedfnam: UNKNOWN FILE TYPE. File system error? 'ls -ld' says: "
		ls -ld $file 2>&1
	fi
DONE
