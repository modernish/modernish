#! test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# Regression tests for the str() string matching tests function.

# --- str match ---

# Printing characters:
TEST title='glob: *'
	str match 'a\bcde' 'a\\*e' || return 1
ENDT
TEST title='non-glob: escaped *'
	thisshellhas BUG_DQGLOB && okmsg='BUG_DQGLOB worked around'
	not str match 'a\bcde' "a\*e"
ENDT
TEST title='glob * matches literal *'
	str match 'a*e' 'a*e' || return 1
ENDT
TEST title='escaped * matches literal *'
	str match 'a*e' 'a\*e' || return 1
ENDT
TEST title='backslash-escaping'
	str match 'abc* d?e' '\a\b\c\* \d\?\e' || return 1
ENDT
TEST title='backslash in bracket pattern'
	str match '\' '[abc\\def]' || return 1
ENDT
TEST title='shell-unsafe chars with "?" glob'
	str match x\'\"\)x ?\'\"\)? || return 1
ENDT
TEST title='quotes in pattern: no special meaning'
	not str match a \"a\"
ENDT
TEST title='semicolon, space, escaped regular char'
	str match 'test; echo hi' '*; \e*' || return 1
ENDT
TEST title='backslash-escaped backslash'
	str match '\' '\\' || return 1
ENDT
TEST title='unescaped (dangling) final backslash'
	str match '\' '\' || return 1
	str match '\\' '\\\' || return 1
	str match '\\\' '\\\\\' || return 1
	str match '\\\\' '\\\\\\\' || return 1
	str match '\\\\\' '\\\\\\\\\' || return 1
	str match 'foo\' 'foo\' || return 1
	str match 'foo\\' 'foo\\\' || return 1
	str match 'foo\\\' 'foo\\\\\' || return 1
	str match 'foo\\\\' 'foo\\\\\\\' || return 1
	str match 'foo\\\\\' 'foo\\\\\\\\\' || return 1
ENDT
TEST title='backslash-escaped newline'
	str match "$CCn" "\\$CCn" || return 1
ENDT

# Control characters:
TEST title="32 control characters"
	str match "ab${CC01}cd" "\a\b${CC01}\c\d" || failmsg="${failmsg-}CC01 "
	str match "ab${CC02}cd" "\a\b${CC02}\c\d" || failmsg="${failmsg-}CC02 "
	str match "ab${CC03}cd" "\a\b${CC03}\c\d" || failmsg="${failmsg-}CC03 "
	str match "ab${CC04}cd" "\a\b${CC04}\c\d" || failmsg="${failmsg-}CC04 "
	str match "ab${CC05}cd" "\a\b${CC05}\c\d" || failmsg="${failmsg-}CC05 "
	str match "ab${CC06}cd" "\a\b${CC06}\c\d" || failmsg="${failmsg-}CC06 "
	str match "ab${CC07}cd" "\a\b${CC07}\c\d" || failmsg="${failmsg-}CC07 "
	str match "ab${CC08}cd" "\a\b${CC08}\c\d" || failmsg="${failmsg-}CC08 "
	str match "ab${CC09}cd" "\a\b${CC09}\c\d" || failmsg="${failmsg-}CC09 "
	str match "ab${CC0A}cd" "\a\b${CC0A}\c\d" || failmsg="${failmsg-}CC0A "
	str match "ab${CC0B}cd" "\a\b${CC0B}\c\d" || failmsg="${failmsg-}CC0B "
	str match "ab${CC0C}cd" "\a\b${CC0C}\c\d" || failmsg="${failmsg-}CC0C "
	str match "ab${CC0D}cd" "\a\b${CC0D}\c\d" || failmsg="${failmsg-}CC0D "
	str match "ab${CC0E}cd" "\a\b${CC0E}\c\d" || failmsg="${failmsg-}CC0E "
	str match "ab${CC0F}cd" "\a\b${CC0F}\c\d" || failmsg="${failmsg-}CC0F "
	str match "ab${CC10}cd" "\a\b${CC10}\c\d" || failmsg="${failmsg-}CC10 "
	str match "ab${CC11}cd" "\a\b${CC11}\c\d" || failmsg="${failmsg-}CC11 "
	str match "ab${CC12}cd" "\a\b${CC12}\c\d" || failmsg="${failmsg-}CC12 "
	str match "ab${CC13}cd" "\a\b${CC13}\c\d" || failmsg="${failmsg-}CC13 "
	str match "ab${CC14}cd" "\a\b${CC14}\c\d" || failmsg="${failmsg-}CC14 "
	str match "ab${CC15}cd" "\a\b${CC15}\c\d" || failmsg="${failmsg-}CC15 "
	str match "ab${CC16}cd" "\a\b${CC16}\c\d" || failmsg="${failmsg-}CC16 "
	str match "ab${CC17}cd" "\a\b${CC17}\c\d" || failmsg="${failmsg-}CC17 "
	str match "ab${CC18}cd" "\a\b${CC18}\c\d" || failmsg="${failmsg-}CC18 "
	str match "ab${CC19}cd" "\a\b${CC19}\c\d" || failmsg="${failmsg-}CC19 "
	str match "ab${CC1A}cd" "\a\b${CC1A}\c\d" || failmsg="${failmsg-}CC1A "
	str match "ab${CC1B}cd" "\a\b${CC1B}\c\d" || failmsg="${failmsg-}CC1B "
	str match "ab${CC1C}cd" "\a\b${CC1C}\c\d" || failmsg="${failmsg-}CC1C "
	str match "ab${CC1D}cd" "\a\b${CC1D}\c\d" || failmsg="${failmsg-}CC1D "
	str match "ab${CC1E}cd" "\a\b${CC1E}\c\d" || failmsg="${failmsg-}CC1E "
	str match "ab${CC1F}cd" "\a\b${CC1F}\c\d" || failmsg="${failmsg-}CC1F "
	str match "ab${CC7F}cd" "\a\b${CC7F}\c\d" || failmsg="${failmsg-}CC7F "
	not isset failmsg || return 1
	not isset xfailmsg || return 2
ENDT

TEST title="32 escaped control characters"
	str match "ab${CC01}cd" "\a\b\\${CC01}\c\d" || failmsg="${failmsg-}CC01 "
	str match "ab${CC02}cd" "\a\b\\${CC02}\c\d" || failmsg="${failmsg-}CC02 "
	str match "ab${CC03}cd" "\a\b\\${CC03}\c\d" || failmsg="${failmsg-}CC03 "
	str match "ab${CC04}cd" "\a\b\\${CC04}\c\d" || failmsg="${failmsg-}CC04 "
	str match "ab${CC05}cd" "\a\b\\${CC05}\c\d" || failmsg="${failmsg-}CC05 "
	str match "ab${CC06}cd" "\a\b\\${CC06}\c\d" || failmsg="${failmsg-}CC06 "
	str match "ab${CC07}cd" "\a\b\\${CC07}\c\d" || failmsg="${failmsg-}CC07 "
	str match "ab${CC08}cd" "\a\b\\${CC08}\c\d" || failmsg="${failmsg-}CC08 "
	str match "ab${CC09}cd" "\a\b\\${CC09}\c\d" || failmsg="${failmsg-}CC09 "
	str match "ab${CC0A}cd" "\a\b\\${CC0A}\c\d" || failmsg="${failmsg-}CC0A "
	str match "ab${CC0B}cd" "\a\b\\${CC0B}\c\d" || failmsg="${failmsg-}CC0B "
	str match "ab${CC0C}cd" "\a\b\\${CC0C}\c\d" || failmsg="${failmsg-}CC0C "
	str match "ab${CC0D}cd" "\a\b\\${CC0D}\c\d" || failmsg="${failmsg-}CC0D "
	str match "ab${CC0E}cd" "\a\b\\${CC0E}\c\d" || failmsg="${failmsg-}CC0E "
	str match "ab${CC0F}cd" "\a\b\\${CC0F}\c\d" || failmsg="${failmsg-}CC0F "
	str match "ab${CC10}cd" "\a\b\\${CC10}\c\d" || failmsg="${failmsg-}CC10 "
	str match "ab${CC11}cd" "\a\b\\${CC11}\c\d" || failmsg="${failmsg-}CC11 "
	str match "ab${CC12}cd" "\a\b\\${CC12}\c\d" || failmsg="${failmsg-}CC12 "
	str match "ab${CC13}cd" "\a\b\\${CC13}\c\d" || failmsg="${failmsg-}CC13 "
	str match "ab${CC14}cd" "\a\b\\${CC14}\c\d" || failmsg="${failmsg-}CC14 "
	str match "ab${CC15}cd" "\a\b\\${CC15}\c\d" || failmsg="${failmsg-}CC15 "
	str match "ab${CC16}cd" "\a\b\\${CC16}\c\d" || failmsg="${failmsg-}CC16 "
	str match "ab${CC17}cd" "\a\b\\${CC17}\c\d" || failmsg="${failmsg-}CC17 "
	str match "ab${CC18}cd" "\a\b\\${CC18}\c\d" || failmsg="${failmsg-}CC18 "
	str match "ab${CC19}cd" "\a\b\\${CC19}\c\d" || failmsg="${failmsg-}CC19 "
	str match "ab${CC1A}cd" "\a\b\\${CC1A}\c\d" || failmsg="${failmsg-}CC1A "
	str match "ab${CC1B}cd" "\a\b\\${CC1B}\c\d" || failmsg="${failmsg-}CC1B "
	str match "ab${CC1C}cd" "\a\b\\${CC1C}\c\d" || failmsg="${failmsg-}CC1C "
	str match "ab${CC1D}cd" "\a\b\\${CC1D}\c\d" || failmsg="${failmsg-}CC1D "
	str match "ab${CC1E}cd" "\a\b\\${CC1E}\c\d" || failmsg="${failmsg-}CC1E "
	str match "ab${CC1F}cd" "\a\b\\${CC1F}\c\d" || failmsg="${failmsg-}CC1F "
	str match "ab${CC7F}cd" "\a\b\\${CC7F}\c\d" || failmsg="${failmsg-}CC7F "
	not isset failmsg || return 1
	not isset xfailmsg || return 2
ENDT

TEST title="']' at start of bracket pattern"
	var=]abc
	str match b *[$var]* \
	&& str match ] *[$var]* \
	&& str match d *[!$var]* \
	|| return 1
ENDT

TEST title="backslash-escaped ']' in bracket pattern"
	var=a\\]bc
	str match b *[$var]* \
	&& str match ] *[$var]* \
	&& str match d *[!$var]* \
	|| return 1
ENDT

TEST title="bracket pattern with \$SHELLSAFECHARS"
	str match @ *[$SHELLSAFECHARS]* \
	&& str match \\ *[!$SHELLSAFECHARS]* \
	&& not str match \# *[$SHELLSAFECHARS]*
ENDT

TEST title="bracket pattern with \$ASCIICHARS"
	str match \\ *[$ASCIICHARS]* \
	&& str match ] *[$ASCIICHARS]* \
	|| return 1
ENDT

TEST title="bracket pattern with \$ASCIICHARS - neg."
	# try to get a valid non-ASCII character in current locale
	# (iconv on DragonFlyBSD returns status 0 when printing an error, so also check stderr output)
	v=$testdir/match.t.019.iconv.stderr
	foo=$(umask 022; printf '\247\n' | extern -p iconv -f ISO8859-1 2>$v)
	if gt $? 0 || is nonempty $v; then
		skipmsg="'iconv' failed"
		return 3
	fi
	case $foo in
	( '' | *[$ASCIICHARS]* )
		skipmsg='ASCII-only locale'
		return 3 ;;
	esac
	str match $foo *[!$ASCIICHARS]* \
	&& not str match $foo *[$ASCIICHARS]*
ENDT

TEST title="pattern is not matched as literal string"
	# tests BUG_CASELIT resistance
	not str match '[abc]' '[abc]' \
	&& not str match '[0-9]' '[0-9]' \
	&& not str match '[:alnum:]' '[:alnum:]'
ENDT

# --- str ematch ---

TEST title="ematch: char. classes, newlines, bounds"
	str ematch "ONE S@ME TWO${CCv}ONE t;hi,n.gs TWO${CCn}" \
		'^(ONE [[:punct:][:alpha:]]{4,9} TWO[[:space:]]){2}$' \
	|| return 1
ENDT

TEST title="ematch: multi-matching using bounds"
	str -M ematch a ab abc abcd abcde abcdef abcdefg abcdefgh abcdefghi abcdefghij '^[[:alpha:]]{3,7}$'
	eq $? 5 && str eq $REPLY abc${CCn}abcd${CCn}abcde${CCn}abcdef${CCn}abcdefg || return 1
ENDT

TEST title="ematch: multibyte characters"
	utf8Locale || return
	str ematch 'éÜåбФшΔηχ' '^[[:alpha:]]{9}$' || mustHave WRN_EREMBYTE
ENDT

# --- empty removal handling ---

# Shells are expected to entirely remove words consisting of an unquoted empty variable expansion,
# not even leaving an empty argument -- even in the safe mode. Unlike test/[, str() is designed
# to cope with this. These tests check that this works correctly.

TEST title='empty removal: unary operators'
	v=
	str empty $v || return 1
	str empty '' || return 1
	str isvarname $v && return 1
	str isvarname '' && return 1
	str isint $v && return 1
	str isint '' && return 1
	return 0
ENDT

TEST title='empty removal: binary operators'
	v=
	str eq $v $v || return 1
	str eq $v '' || return 1
	str ne $v $v && return 1
	str ne $v '' && return 1
	str begin $v $v || return 1
	str begin $v '' || return 1
	str end $v $v || return 1
	str end $v '' || return 1
	str match $v $v || return 1
	str match $v '' || return 1
	str ematch $v '^$' || return 1
	str lt $v $v && return 1
	str lt $v '' && return 1
	str gt $v $v && return 1
	str gt $v '' && return 1
	str le $v $v || return 1
	str le $v '' || return 1
	str ge $v $v || return 1
	str ge $v '' || return 1
	return 0
ENDT

TEST title='empty removal: multi-matching'
	v=
	str -M eq $v $v $v	; eq $? 0 && isset REPLY && str empty "$REPLY" || return 1
	str -M eq $v $v ''	; eq $? 0 && isset REPLY && str empty "$REPLY" || return 1
	str -M ne $v $v $v	; eq $? 1 && not isset REPLY || return 1
	str -M ne $v $v ''	; eq $? 1 && not isset REPLY || return 1
	str -M begin $v $v $v	; eq $? 0 && isset REPLY && str empty "$REPLY" || return 1
	str -M begin $v $v ''	; eq $? 0 && isset REPLY && str empty "$REPLY" || return 1
	str -M end $v $v $v	; eq $? 0 && isset REPLY && str empty "$REPLY" || return 1
	str -M end $v $v ''	; eq $? 0 && isset REPLY && str empty "$REPLY" || return 1
	str -M match $v $v $v	; eq $? 0 && isset REPLY && str empty "$REPLY" || return 1
	str -M match $v $v ''	; eq $? 0 && isset REPLY && str empty "$REPLY" || return 1
	str -M ematch $v $v '^$'; eq $? 0 && isset REPLY && str empty "$REPLY" || return 1
	str -M lt $v $v $v	; eq $? 1 && not isset REPLY || return 1
	str -M lt $v $v ''	; eq $? 1 && not isset REPLY || return 1
	str -M gt $v $v $v	; eq $? 1 && not isset REPLY || return 1
	str -M gt $v $v ''	; eq $? 1 && not isset REPLY || return 1
	str -M le $v $v $v	; eq $? 0 && isset REPLY && str empty "$REPLY" || return 1
	str -M le $v $v ''	; eq $? 0 && isset REPLY && str empty "$REPLY" || return 1
	str -M ge $v $v $v	; eq $? 0 && isset REPLY && str empty "$REPLY" || return 1
	str -M ge $v $v ''	; eq $? 0 && isset REPLY && str empty "$REPLY" || return 1
	return 0
ENDT
