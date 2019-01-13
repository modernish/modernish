#! test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# Regression tests related to modernish shellquote() and the shell's quoting mechanisms.

# ---- shellquote() ----

readonly \
shellquote_numstrings=4 \
shellquote_orig_string_1=\' \
shellquote_orig_string_2=a\"${CCv}\$d${CCa}ef${CC01}g\`${CCn}ij${CC7F}\\l${CCr}mn \
shellquote_orig_string_3=$ASCIICHARS \
shellquote_orig_string_4="

	hi t\$here,
	let's check	h\\ôw \`this\` prógram
	handles 'quoting' of \\weird multi#line *strings*.

\\\\\\
	\\ \\  \\  

"

do_shellquote_test() {
	title="$1 levels of shellquote${2:+ $2} and back"
	LOCAL e=0 i=0 lvl ostring qstring; BEGIN
		while le i+=1 shellquote_numstrings; do
			eval ostring=\${shellquote_orig_string_$i}
			qstring=$ostring
			lvl=0
			while le lvl+=1 $1; do
				shellquote ${2+$2} qstring  # BUG_PSUBEMPT compat: don't use ${2-} here
				if not str in ${2-} P && str in $qstring $CCn; then
					failmsg='non-P result w/ newline'
					return 1
				fi
			done
			append --sep=';' okmsg "${#qstring}c"
			while gt lvl-=1 0; do
				if not (PATH=/dev/null; set -e; eval "qstring=$qstring"); then
					failmsg="quoted string doesn't eval"
					return 1
				fi
				eval qstring=$qstring
			done
			if not str eq $qstring $ostring; then
				failmsg='unquoted string not identical'
				return 1
			fi
		done
	END
}

TEST
	runExpensive && v=12 || v=4
	do_shellquote_test $v
ENDT

TEST
	runExpensive && v=9 || v=4
	do_shellquote_test $v -f
ENDT

TEST
	runExpensive && v=11 || v=4
	do_shellquote_test $v -P
ENDT

TEST
	runExpensive && v=8 || v=4
	do_shellquote_test $v -fP
ENDT

# --- the shell's quoting mechanisms ----

TEST title='shell quoting within bracket patterns'
	case foo in
	( f['n-p']o | f["!"@]o )
		mustHave BUG_BRACQUOT ;;
	( f[n-p]o )
		mustNotHave BUG_BRACQUOT ;;
	( * )	return 1 ;;
	esac
ENDT

TEST title='C-style quoting in command substitution'
	# regression test for CESCQUOT and BUG_DOLRCSUB
	foo=$(printf '{%s}' $'bar' $$'bar' $$$'bar' $$$$'bar')
	case $foo in
	( {\$bar}{${$}bar}{${$}\$bar}{${$}${$}bar} )
		okmsg='no CESCQUOT'
		mustNotHave CESCQUOT && mustNotHave BUG_DOLRCSUB ;;
	( {bar}{${$}bar}{${$}bar}{${$}${$}bar} )
		mustHave CESCQUOT && mustNotHave BUG_DOLRCSUB  ;;
	( {bar}{bar}{${$}bar}{${$}bar} )
		mustHave CESCQUOT && mustHave BUG_DOLRCSUB ;;
	( * )	return 1 ;;
	esac
ENDT

TEST title='quotes within $(command substitutions)'
	v=$(
		eval 'put $(put "a")'
		eval "put \$(put 'b' # '$CCn)" 2>/dev/null
	)
	case $v in
	( a )	failmsg=FTL_CSCMTQUOT; return 1 ;;
	( ab )	;;
	( * )	return 1 ;;
	esac
ENDT
