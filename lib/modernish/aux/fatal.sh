#! fatal/bug/test/for/moderni/sh
#
# This script is a battery of fatal bug tests for modernish init, invoked
# as a dot script within a command substitution subshell in bin/modernish,
# install.sh, and uninstall.sh. It exits on the first bug found. This allows
# running most tests without forking additional subshells, improving init
# performance at the cost of not generating a complete report.
#
# The uppercase FTL_* bug IDs in the comments were formerly used to report
# these bugs to the user. They are still handy for reference and grepping.
#
# --- begin license ---
# Copyright (c) 2019 Martijn Dekker <martijn@inlv.org>, Groningen, Netherlands
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# --- end license ---

# To avoid a segfault on AT&T ksh93, fork this subshell.
command ulimit -t unlimited 2>/dev/null

# Make sure no spurious external commands are executed while allowing 'yash -o posix' to use builtins.
PATH=${DEFPATH:=$(getconf PATH)} || exit

# Produce non-matching output on premature exit.
trap 'echo fatalbug' 0	# BUG_TRAPEXIT compat

# To see where a shell fails, export MSH_FTL_DEBUG.
case ${MSH_FTL_DEBUG+d} in
( d )	set -o xtrace ;;
( * )	exec 2>/dev/null ;;
esac || exit

# Set safe defaults.
IFS=''; set +e -fCu


# ___ Bugs with shell grammar _________________________________________________

# FTL_CSCMTQUOT: Quotes in comments within $(command substitutions) are wrongly
# parsed, with unbalanced quotes causing a syntax error. (pdksh; bash < 3.1)
eval ': || $( : # "
)' || exit

# FTL_FORSCOLON: Spurious syntax error caused by the ';' after 'for i' (yash -o posix < 2.44),
# or by that ';' followed by a newline (AT&T ksh93 < 93u+).
eval ': || for i;
do :; done' || exit

# FTL_SQBKSL: dash 0.5.10, 0.5.10.1
# Backslashes are misparsed in single-quoted strings.
case 'foo\
bar' in
( foo\\"
"bar )	;;
( * )	exit ;;
esac

# FTL_ASGNBIERR: Variable assignments preceding regular builtin commands
# should not persist after the command exits, but with this bug they do if
# the command exits with an error. This may break various scripts in obscure
# ways and certainly destroys some modernish feature tests (particularly,
# 'PATH=temp_path builtin_with_error' causes the temporary $PATH to persist!)
# Bug found on AT&T ksh93 version "M 1993-12-28 r".
t=ok
t=bug command -@	# invalid option triggers error
case ${t} in
( ok )	;;
( * )	exit ;;
esac

# FTL_ORNOT: '!' does not invert the exit status of a 'case' after '||'
# (discovered in busybox ash 1.25.0git; no one runs old dev code, but it is
# trivial to test for this in case another shell ever has a bug with '!')
{ ! : || ! case x in x) ;; esac; } && exit

# FTL_SUBSHEXIT: Incorrect exit status of commands within subshells.
# (bash 4.3 and 4.4, if compiled without job control)
# Ref.: https://lists.gnu.org/archive/html/bug-bash/2016-09/msg00083.html
# Do evil shell version checking to save two subshell forks on other shells.
case ${BASH_VERSION-} in
( 4.[34].* )
	(false)
	(false) && exit ;;
esac


# ___ Bugs with shell builtin utilities and variables _________________________

# FTL_NOPPID: no $PPID variable (parent's process ID). (NetBSD sh)
case ${PPID-} in
( '' | 0* | *[!0123456789]* )
	exit ;;
esac

# Make sure that we have a way to guarantee running a shell builtin.
# Note: we can only use 'special builtins' here or yash in posix mode will fail this test.
# See: http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_14
# FTL_NOCOMMAND: Debian posh; zsh < 4.2
# FTL_CMDVRESV: 'command -v' does not find reserved words such as "if" (mksh < R51)
PATH=/dev/null
{	t=x
	command -v unset \
	&& command -V unset \
	&& command -v if \
	&& command unset t \
	&& case ${t+s} in ( s ) exit ;; esac
} >/dev/null || exit
PATH=$DEFPATH

# FTL_CMDSPEXIT: on all known shells without other fatal errors, we should be
# able to use 'command' to turn off braceexpand or check for (in)valid typeset
# options without exiting the shell if the option doesn't exist.
command set +o braceexpand
PATH=/dev/null command -v typeset >|/dev/null && command typeset -@ foo

# FTL_ROASSIGN: 'readonly' command doesn't support assignment. (unpatched pdksh)
# Warning: literal control characters ^A and DEL below. Most editors handle this gracefully.
readonly CC01='' CC7F='' "RO=ok"
case $CC01,$CC7F,$RO,,,ok in
( ,,ok,$CC01,$CC7F,$RO ) ;;
( * )	exit ;;
esac

# FTL_ROSERIES: 'readonly' can't make a series of variables read-only.
RO1=1 RO2=2 RO3=3
readonly RO1 RO2 RO3 || exit

# FTL_NOALIAS: No aliases (Debian posh; bash "minimal configuration").
alias test=test || exit

# FTL_EVALALIAS: aliases aren't expanded in 'eval'.
fn() { ! :; }
alias fn=:
eval fn || exit

# FTL_UNALIASA: Can't remove all aliases.
unalias -a || exit

# FTL_NOFNOVER: Can't override shell builtins with shell functions. (ksh88)
echo() { :; } && unset -f echo || exit

# FTL_NOKILLS: No 'kill -s' syntax.
kill -s 0 $$ || exit

# FTL_EVALERR: 'eval' does not return an error exit status (> 0) on syntax
# error. This kills all feature testing based on shell grammar features,
# giving false positives on tests like HERESTR.t, causing subsequent breakage.
# (Found on busybox 1.26.0)
#	(The extra 'command' is needed for compatibility with a bug in dash,
#	triggered because this script was invoked with 'command .'.)
(command eval '(') && exit

# FTL_EVALRET: shell doesn't return from a function if the "return"
# is within an 'eval', but only from the 'eval'. (yash < 2.39)
# http://osdn.jp/ticket/browse.php?group_id=3863&tid=35232
fn() { : ; eval "return $?"; ! : ; }
fn || exit

# FTL_UNSETFAIL: the 'unset' command sets a non-zero (fail) exit status if
# the variable to unset was either not set (some pdksh versions), or never
# set before (AT&T ksh 1993-12-28). This is contrary to POSIX, which says:
# "Unsetting a variable or function that was not previously set shall not be
# considered an error [...]". Reference:
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_29_03
# To detect this bug on AT&T ksh, use a variable that we're pretty sure was
# never set before in any program in the world, ever ('uuidgen' helped).
unset -v FTL_UNSETFAIL_D7CDE27B_C03A_4B45_8050_30A9292BDE74 || exit

# FTL_TESTEXIT: On zsh, using '=~' in the 'test' command exits the shell if
# its regex module fails to load. Modernish init would fail, so fail early.
command test foo '=~' bar

# FTL_TESTERR0: 'test'/'[' exits successfully (exit status 0)
# if an invalid argument is given to an operator. (mksh < R52)
command test 123 -eq 1XX && exit

# FTL_LETSEGV: on NixOS, mksh segfaults on 'let --'.
PATH=/dev/null command -v let >/dev/null && let --


# ___ Bugs with parameter expansions __________________________________________

# FTL_PARONEARG: When IFS is empty on most versions of pdksh (i.e. field splitting is off),
# "$@" fails to generate separate words for each PP and joins the PPs together instead.
set -- "   \on\e" "\tw'o" " \th\'re\e" " \\'fo\u\r "
IFS=''
set -- "$@"
case $# in
( 4 )	;;
( * )	exit ;;
esac

# FTL_UPP (Unset Positional Parameters): Cannot access "$@" or "$*" if set -u
# (-o nounset) is active and there are no positional parameters. If that
# option is set, NetBSD /bin/sh and older versions of ksh93 and pdksh error
# out on accessing "$@" and "$*" (the collective positional parameters), even
# if that access is implicit in a 'for' loop (as in 'for var do stuff; done').
# This is against the standard:
#     "-u: When the shell tries to expand an unset parameter OTHER THAN THE
#     '@' AND '*' SPECIAL PARAMETERS, it shall write a message to standard
#     error and shall not execute the command containing the expansion [...]".
# Reference:
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_25_03
# (under '-u').
set -u -- && set -- "$@" && t=$* && for t do :; done || exit

# FTL_SUBSTIFS: parameter substitution changes all existing spaces in the
# variable to the first character in IFS. (zsh 4.1.1)
t='1 2 3'
IFS='x '  # this zsh bug is only triggered if IFS has space as 2nd char
t=${t+$t }4\ 5
IFS=''
case ${t} in
( '1 2 3 4 5' )	;;
( * ) exit ;;
esac

# FTL_PSUB: parameter substitution fails to match certain
# patterns. (yash < 2.40)
#  *  The parameter expansion ${foo##bar*} was being treated like
#     ${foo##bar} where the asterisk should match up to the end of the
#     parameter value.
#  *  The parameter expansion ${foo%%*} was being expanded to ${foo}
#     where it should expand to an empty string.
t='barbarfoo'
case ${t##bar*}/${t%%*} in
( / )	;;
( * )	exit ;;
esac

# FTL_PSUB2: glob patterns in parameter substitutions (#, %, ##, %%) are wrongly
# subject to parsing under certain conditions: expansions, command substitution,
# backslash parsing. (bosh/schily sh <= 2017-11-21)
t='a${t2=BUG}'
unset -v t2
t=${t%"${t#a}"}   # "
case ${t},${t2-}, in	# FTL_PSUB4 compat: extra comma
( 'a,,' ) ;;
( * )	exit ;;
esac

# FTL_PSUB3: glob patterns in parameter substitutions (#, %, ##, %%) cause
# quoted patterns to not match. (bosh/schily sh 2018-03-01)
t=abcdefghij
t2=efg
case ${t#*"$t2"} in
( hij ) ;;
( * )	exit ;;
esac

# FTL_PSUB4: a parameter substitution of the form ${var-} or ${var:-},
# at the end of an argument, erases the entire argument. (mksh R50d)
t=
case foo${t:-} in
( '' )	exit ;;
esac

# FTL_PSUBPP: if a parameter substitution modifies one positional parameter with a
# pattern containing another positional parameter, the result is corrupted. (pdksh)
set ' foo -> bar' foo
case ${1#" $2 -> "} in
( bar ) ;;
( * ) exit ;;
esac

# FTL_HASHVAR: $#var means the length of $var - other shells and POSIX require braces, as in ${#var}. This
# causes interesting bugs when combining $#, being the number of positional parameters, with other strings.
t=$$
case $#${t},$(($#-1+1)) in
( "${#}${$},${#}" )
	;;
( * )	exit ;;
esac

# FTL_CC7F: bash 2.05b and 3.0 have bugs with deleting $CC7F from expansions.
t=$RO$CC01$CC7F$RO
case ${#t} in
( 6 )	;;
( * )	exit ;;
esac

# FTL_UTFLENGTH: Fatal error in measuring UTF-8 string length.
case ${LC_ALL:-${LC_CTYPE:-${LANG:-}}} in
( *.[Uu][Tt][Ff]8 | *.[Uu][Tt][Ff]-8 )
	t='bèta' # 4 char, 5 byte UTF-8 string 'beta' with accent grave on 'e'
	case ${#t} in
	( 4 | 5 ) ;;  # ok or WRN_MULTIBYTE
	( * )	exit ;;
	esac
esac


# ___ Bugs with field splitting _______________________________________________

# Fatal field splitting bugs. This is known to catch the following:
# FTL_IFSWHSP:	Incorrect IFS whitespace removal. (pdksh)
# FTL_IFSBKSL:	Field splitting eats initial backslashes. (yash 2.8 to 2.37)
# FTL_IFSEFODB:	Field splitting eats first of double backslash. (zsh < 4.2.7)
# FTL_IFSWHSPE:	Bug with IFS whitespace: an initial empty whitespace-separated field appears
#		at the end of the expansion result instead of the start if IFS contains both
#		whitespace and non-whitespace characters. (ksh93 Version M 1993-12-28 p)
# FTL_IFSNONWH:	Non-whitespace ignored in field splitting. (ksh93 with a DEBUG trap set)
# FTL_NOFSPLIT:	No field splitting. (Native zsh mode?)
t='  ::  \on\e :\tw'\''o \th\'\''re\e :\\'\''fo\u\r:   : :  '
IFS=': '
set -- ${t}
IFS=''
t=${#},${1-U},${2-U},${3-U},${4-U},${5-U},${6-U},${7-U},${8-U},${9-U},${10-U},${11-U},${12-U}
case ${t} in
( '8,,,\on\e,\tw'\''o,\th\'\''re\e,\\'\''fo\u\r,,,U,U,U,U' \
| '9,,,\on\e,\tw'\''o,\th\'\''re\e,\\'\''fo\u\r,,,,U,U,U' )  # QRK_IFSFINAL
	;;
( * ) exit ;;
esac

# FTL_TILDSPLIT: Tilde expansion is subject to field splitting. (dash < 0.5.7)
case $HOME in
( /* ) ;;
( * ) HOME=/dev/null/n ;;
esac
IFS='/'
set -- ~
IFS=''
case ${#},${1-} in
( 1,/* ) ;;
( * ) exit ;;
esac


# ___ Bugs with shell arithmetic ______________________________________________

# FTL_NOARITH: incomplete POSIX shell arithmetic support.
# (NetBSD /bin/sh, Slackware /bin/ash, original pdksh (no hex or octal)).
i=7
j=0
case $(( ((j+=6*i)==0x2A)>0 ? 014 : 015 )) in
( 12 ) ;;
( * )	exit ;;
esac
case $j in
( 42 )	;;
( * )	exit ;;
esac

# FTL_ARITHPREC: on dash <= 0.5.5.1, binary operator parsing doesn't
# respect operator precedence correctly in the case where a lower-
# precedence operator is followed by a higher-precedence operator,
# and then by a lower-precedence operator. (dash-git commit 9655c1ac)
case $((37-16%7+9)) in
( 44 )	;;
( * )	exit ;;
esac

# FTL_ROUNDMLN: AT&T ksh version "M 1993-12-28 s+" (pre-installed version
# on Mac OS X 10.7) has rounding errors in integer arithmetic when ordinary
# shell assignments or comparisons are used on numbers greater than one
# million; only pure shell arithmetic expressions work (up to 64 bits).
# FTL_ARITHASGN: Arithmetic assignment fails if the variable already
# contains a value that cannot be converted to arithmetic. (yash < 2.40)
unset -v t2
command -v typeset >/dev/null && typeset -i t2  # suppress ksh93 rendering variable as float exponential
t2=$((1000005))
t=foo\\bar
: "$((t = 1000005))" || exit
case "${t2},$((1000001)),$((1000005)),${t}" in
( 1000005,1000001,1000005,1000005 ) ;;
( * )	exit ;;
esac
unset -v t2  # undo typeset -i


# ___ Bugs with pattern matching ______________________________________________

# FTL_CASECC: glob patterns as in 'case' cannot match an escaped literal ^A ($CC01) or DEL
# ($CC7F) control character. This kills modernish 'str match'. Found on: bash 2.05b, 3.0, 3.1
eval "case 'ab${CC01}c${CC7F}d' in
( \\a\\b\\${CC01}\\c\\${CC7F}\\d ) ;;
( * )	exit ;;
esac"

# FTL_FOURTEEN: pdksh 5.2.14nb5 from NetBSD pkgsrc has a very obscure bug: it fails to match a list of
# characters from a variable in a bracket pattern, but only if the variable name is exactly 14 characters
# long! This breaks bracket patterns with $SHELLSAFECHARS (a 14 character variable name).
_Msh_test_1234=x	# 14 character variable name
case x in
( [${_Msh_test_1234}] ) ;;
( * )	exit ;;
esac

# FTL_BRACSQBR: the closing square bracket ']', even if escaped or passed
# from a quoted variable, causes a non-match in a glob bracket pattern, even
# if another character is matched. In other words, bracket patterns can never
# contain the closing square bracket as a character to match.
# Bug found on:
# - older FreeBSD /bin/sh
# - AT&T ksh93 "JM 93t+ 2010-03-05" and "JM 93t+ 2010-06-21"
t='ab]cd'
case c in
( *["${t}"]* )
	case e in
	( *[!"${t}"]* ) ;;
	( * ) exit ;;
	esac ;;
( * )	exit ;;
esac

# FTL_BRACHYPH: a hyphen anywhere in a bracket pattern always produces a
# positive match. (AT&T ksh Version M 1993-12-28 p, at least on Mac OS X 10.4)
case e in
( [a-] | [a-d] | [-a] ) exit ;;
esac

# FTL_GLOBHIBYT: glob patterns don't match high-byte characters (> 127).
# Found in bosh when compiled on Linux. Probably a bug in glibc.
# A variant was found on yash on Solaris under an ISO-8859-1 locale.
case XaYöb in
( X*Y* )	;;
( * | XaYöb )	exit ;;
esac

# FTL_CASEBKSL: Double-quoted patterns don't match unescaped backslashes. (found in Busybox ash 1.28.0)
case \\z in
( "\z" ) ;;
( * )	exit ;;
esac

# FTL_CASEBKSL2: Backslashes aren't matched correctly when passed down from positional parameters. (NetBSD 8.1 sh)
set -- \\
case ab\\cd in
( *"$1"* ) ;;
( * ) 	exit ;;
esac

# FTL_EMPTYBRE: empty bracket expressions eat subsequent shell grammar, producing unexpected results (in the
# test example below, a false positive match, because the two patterns are taken as one, with the "|" being
# taken as part of the bracket expression rather than shell grammar separating two bracket expressions).
t=''
case abc in
( ["${t}"] | [!a-z]* )
	exit ;;
esac

# FTL_BASHGCC82: fatal 'case' matching bug on bash compiled by a broken gcc 8.2.
# Ref.: https://lists.gnu.org/archive/html/bug-bash/2019-01/msg00149.html
case "a-b" in *-*-*) exit ;; esac

# FTL_UTFCASE: shell cannot relibaly compare UTF-8 characters.
# (found on busybox with CONFIG_LOCALE_SUPPORT enabled)
case "ρ" in
( "ρ" )	;;
( * )	exit ;;
esac


# ___ Bugs with redirection ___________________________________________________

# FTL_DEVCLOBBR: Can't redirect output to devices if 'set -C' is active
# (a.k.a. 'set -o noclobber'). Workaround: use >| instead of >.  Found on:
# - NetBSD sh <= 8.0
# - bash 4.1 on Cygwin (for /dev/tty only; can only test this if we have a tty)
set -C
if command test -c /dev/tty >|/dev/tty; then
	: >/dev/tty
else
	: >/dev/null
fi || exit

# FTL_FNREDIR: I/O redirections on function definition commands are not
# remembered or honoured when the function is executed. (zsh < 5.0.7)
fn() {
	command : <&5
} 5</dev/null
fn 5<&- || exit


# ^^^ add new tests above this line, if possible ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
# ___ Bugs with program flow corruption _______________________________________

# FTL_FLOWCORR1: Program flow corruption if a subshell exits due to an error.
# The bug occurs on zsh < 5.5 running on Solaris and certain Linux distros.
# Ref. (thread): http://www.zsh.org/mla/workers/2017/msg00369.html
#		 http://www.zsh.org/mla/workers/2017/msg00375.html
case ${ZSH_VERSION+z} in
( z )	# Execution counter.
	t=0
	# Exit from a subshell due to an error triggers the bug.
	(set -o nonexistent_@_option)
	# With the bug, the following will be executed twice.
	case $((t += 1)) in
	( 2 )	echo BAD; exit 1 ;;
	esac ;;
esac

# ___ End of fatal bug tests __________________________________________________

# All passed. Write verification string.
trap - 0  # BUG_TRAPEXIT compat
echo $PPID
