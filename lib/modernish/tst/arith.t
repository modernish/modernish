#! test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# Shell arithmetic-related tests.
# Note: on shells without the 'let' builtin, modernish adds its own.

TEST title='shell arithmetic supports octal'
	case $((014+032)) in
	( 38 )	;;
	( * )	return 1 ;;
	esac
ENDT

TEST title='"let" supports octal'
	# on ksh93, this requires a special option (set -o letoctal); verify that it is set
	let 014+032==38
ENDT

TEST title='"let" handles negative number as 1st arg'
	# check that it is not interpreted as an option
	let "-1" 2>/dev/null || return 1
ENDT

TEST title='check for arithmetic type restriction'
	LOCAL foo; BEGIN
		: $((foo = 0))	# does this assign an arithmetic type restriction?
		foo=4+5		# let's see...
		case $foo in
		( 4+5 )	mustNotHave BUG_ARITHTYPE ;;
		( 9 )	mustHave BUG_ARITHTYPE ;;
		( * )	return 1 ;;
		esac
	END
ENDT

TEST title='handling 64 bit integers'
	# First test if the shell exits on 64-bit numbers:
	if ! ( : $((9000000000)) ) 2>/dev/null; then
		mustHave QRK_32BIT
		return
	fi
	{ foo=$((9000000000)); } 2>/dev/null
	case $foo in
	( 9000000000 )
		mustNotHave QRK_32BIT ;;
	# number wrapped around, 2147483647: number capped at maximum, or number truncated after 9 digits
	( 410065408 | 2147483647 | 900000000 )
		mustHave QRK_32BIT ;;
	( * )	return 1 ;;
	esac
ENDT

TEST title='arith accepts whitespace in var values'
	# POSIX doesn't require shell arithmetic to accept either leading or trailing whitespace in values of variables.
	# This only applies to values that don't result from shell expansions, for example, it applies to $((foo)) but not to
	# $(($foo)). Some shells don't accept trailing whitespace (QRK_ARITHWHSP), but all shells in the wild accept leading
	# whitespace, as a natural consequence of how C library functions like wcstol() work. So we FAIL here otherwise.
	# Ref.: https://osdn.net/projects/yash/ticket/36002
	case $(	v="$CCn$CCt 1"		# newline, tab, space, 1
		{ : $((v)); } 2>/dev/null || exit
		put a1
		v="1$CCn$CCt "		# 1, newline, tab, space
		{ : $((v)); } 2>/dev/null || exit
		put a2
	) in
	( '' )	failmsg='unknown quirk'	# leading whitespace is not trimmed
		return 1 ;;
	(a1a2)	mustNotHave QRK_ARITHWHSP ;;
	(a1)	mustHave QRK_ARITHWHSP ;;
	( * )	return 1 ;;
	esac
ENDT

TEST title='handling of unset variables'
	unset -v foo
	push -u
	set +u
	( bar=$((foo)) ) 2>/dev/null && bar=$((foo))
	pop --keepstatus -u
	if so; then
		mustNotHave BUG_ARITHINIT
	else
		mustHave BUG_ARITHINIT
	fi
ENDT

TEST title='handling of empty variables'
	foo=''
	( bar=$((foo)) ) 2>/dev/null && bar=$((foo))
	if not so; then
		mustHave BUG_ARITHINIT
		return
	fi
	case $bar in
	( 0 )	mustNotHave QRK_ARITHEMPT ;;
	( '' )	mustHave QRK_ARITHEMPT ;;
	( * )	return 1 ;;
	esac
ENDT

TEST title='field splitting of $((arith expansion))'
	push IFS
	IFS=0
	set -- $((12034056))
	pop IFS
	case ${#},${1-U},${2-U},${3-U} in
	( 3,12,34,56 )
		mustNotHave BUG_ARITHSPLT ;;
	( 1,12034056,U,U )
		mustHave BUG_ARITHSPLT ;;
	( * )	return 1 ;;
	esac
ENDT

TEST title='LINENO works in shell arithmetic'
	if not thisshellhas LINENO; then
		skipmsg='no LINENO'
		return 3
	fi
	(	set +o nounset
		# Note: where 'let' is implemented as a shell function, LINENO != $LINENO !!!
		# Use an extra $((arith expansion)) to work around that.
		let $((!LINENO && LINENO == 0 && $LINENO > LINENO)) && exit 113
		let $((LINENO && LINENO > 0 && $LINENO == LINENO)) && exit 42
	)
	case $? in
	( 113 )	mustHave BUG_ARITHLNNO ;;
	( 42 )	mustNotHave BUG_ARITHLNNO ;;
	( * )	return 1 ;;
	esac
ENDT
