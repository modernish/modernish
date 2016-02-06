#! /module/for/moderni/sh

# var/string
# String manipulation functions.


# trim: Strip whitespace (or other characters) from the beginning and end of
# a variable's value. Whitespace is defined by the 'space' character class
# (in the POSIX locale, this is tab, newline, vertical tab, form feed,
# carriage return, and space, but in other locales it may be different).
# Optionally, a string of literal characters to trim can be provided in the
# second argument; any of those characters will be trimmed from the beginning
# and end of the variable's value.
# Usage: trim <varname> [ <characters> ]
# TODO: options -l and -r for trimming on the left or right only.
if thisshellhas BUG_BRACQUOT; then
	if thisshellhas BUG_NOCHCLASS; then
		print "var/string.mm: You're using a shell with both BUG_BRACQUOT and BUG_NOCHCLASS!" \
			"    This is not known to exist, so workaround not implemented. Please report." 1>&2
		return 1
	fi
	# BUG_BRACQUOT: ksh and zsh don't disable the special meaning of
	# characters -, ! and ^ in quoted bracket expressions (even if their
	# values were passed in variables), so e.g. 'trim var a-d' would trim
	# on 'a', 'b', 'c' and 'd', not 'a', '-' and 'd'.
	# This workaround version makes sure '-' is last in the string, which
	# is the standard way of providing a literal '-' in an unquoted bracket
	# expression.
	# A workaround for an initial '!' or '^' is not needed because the
	# bracket expression in the command substitutions below start with a
	# negating '!' anyway, which makes sure any further '!' or '^' don't
	# have any special meaning.
	trim() {
		case ${#},${2-} in
		( 1, )	isvarname "$1" || die "trim: invalid variable name: $1" || return
			eval "$1=\${$1#\"\${$1%%[![:space:]]*}\"}; $1=\${$1%\"\${$1##*[![:space:]]}\"}" ;;
		( 2,*-?* )
			isvarname "$1" || die "trim: invalid variable name: $1" || return
			_Msh_trim_P=$2
			replacein -a _Msh_trim_P - ''
			eval "$1=\${$1#\"\${$1%%[!\"\$_Msh_trim_P\"-]*}\"}; $1=\${$1%\"\${$1##*[!\"\$_Msh_trim_P\"-]}\"}"
			unset -v _Msh_trim_P ;;
		( 2,* )	isvarname "$1" || die "trim: invalid variable name: $1" || return
			eval "$1=\${$1#\"\${$1%%[!\"\$2\"]*}\"}; $1=\${$1%\"\${$1##*[!\"\$2\"]}\"}" ;;
		( * )	die "trim: incorrect number of arguments (was $#, should be 1 or 2)" ;;
		esac
	}
elif thisshellhas BUG_NOCHCLASS; then
	# pdksh, mksh: POSIX character classes such as [:space:] aren't
	# available, so use modernish $WHITESPACE instead. This means no
	# locale-specific whitespace matching.
	trim() {
		case $# in
		( 1 )	isvarname "$1" || die "trim: invalid variable name: $1" || return
			eval "$1=\${$1#\"\${$1%%[!'$WHITESPACE']*}\"}; $1=\${$1%\"\${$1##*[!'$WHITESPACE']}\"}" ;;
		( 2 )	isvarname "$1" || die "trim: invalid variable name: $1" || return
			eval "$1=\${$1#\"\${$1%%[!\"\$2\"]*}\"}; $1=\${$1%\"\${$1##*[!\"\$2\"]}\"}" ;;
		( * )	die "trim: incorrect number of arguments (was $#, should be 1 or 2)" ;;
		esac
	}
else
	# Normal version.
	trim() {
		case $# in
		( 1 )	isvarname "$1" || die "trim: invalid variable name: $1" || return
			eval "$1=\${$1#\"\${$1%%[![:space:]]*}\"}; $1=\${$1%\"\${$1##*[![:space:]]}\"}" ;;
		( 2 )	isvarname "$1" || die "trim: invalid variable name: $1" || return
			eval "$1=\${$1#\"\${$1%%[!\"\$2\"]*}\"}; $1=\${$1%\"\${$1##*[!\"\$2\"]}\"}" ;;
		( * )	die "trim: incorrect number of arguments (was $#, should be 1 or 2)" ;;
		esac
	}
fi

# replacein: Replace first, (-l)ast or (-a)ll occurrences of a string by
# another string in a variable.
#
# Usage: replacein [ -a | -l ] <varname> <oldstring> <newstring>
#
# TODO: support glob
if identic ABQXYFGHIJABCDEFG,ABQXYFGHIJABQXYFG \
	"$(x=ABCDEFGHIJABCDEFG a=CDE b=QXY; eval 'y=${x/"$a"/"$b"}; z=${x//"$a"/"$b"}' && print "$y,$z")"
	# Note: To keep busybox ash from exiting on a 'bad parameter substitution'
	#       syntax error, the feature test needs 'eval' *within* a subshell.
	# TODO: consider whether to make this a main feature test with thisshellhas() identifier
then
	# bash, *ksh, zsh, yash:
	replacein() {
		case ${#},${1-} in
		( 3,* )
			isvarname "$1" || die "replaceallin: invalid variable name: $1" || return
			eval "$1=\${$1/\"\$2\"/\"\$3\"}" ;;
		( 4,-a )
			isvarname "$2" || die "replaceallin: invalid variable name: $2" || return
			eval "$2=\${$2//\"\$3\"/\"\$4\"}" ;;
		( 4,-l )
			isvarname "$2" || die "replaceallin: invalid variable name: $2" || return
			eval "if contains \"\$$2\" \"\$3\"; then
				$2=\${$2%\"\$3\"*}\$4\${$2##*\"\$3\"}
			fi" ;;
		( * )
			die "replaceallin: invalid arguments" ;;
		esac
	}
else
	# POSIX:
	replacein() {
		case ${#},${1-} in
		( 3,* )
			isvarname "$1" || die "replaceallin: invalid variable name: $1" || return
			eval "if contains \"\$$1\" \"\$2\"; then
				$1=\${$1%%\"\$2\"*}\$3\${$1#*\"\$2\"}
			fi" ;;
		( 4,-a )
			isvarname "$2" || die "replaceallin: invalid variable name: $2" || return
			eval "while contains \"\$$2\" \"\$3\"; do
				$2=\${$2%%\"\$3\"*}\$4\${$2#*\"\$3\"}
			done" ;;
		( 4,-l )
			isvarname "$2" || die "replaceallin: invalid variable name: $2" || return
			eval "if contains \"\$$2\" \"\$3\"; then
				$2=\${$2%\"\$3\"*}\$4\${$2##*\"\$3\"}
			fi" ;;
		( * )
			die "replaceallin: invalid arguments" ;;
		esac
	}
fi 2>/dev/null
