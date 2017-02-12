#! test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# Printing characters:
doTest1() {
	title='glob: *'
	match abcde 'a*e'
}
doTest2() {
	title='non-glob: escaped *'
	not match abcde 'a\*e'
}
doTest3() {
	title='glob * matches literal *'
	match 'a*e' 'a*e'
}
doTest4() {
	title='escaped * matches literal *'
	match 'a*e' 'a\*e'
}
doTest5() {
	title='backslash-escaping'
	match 'abc* d?e' '\a\b\c\* \d\?\e'
}
doTest6() {
	title='backslash in bracket pattern'
	match '\' '[abc\\def]'
}
doTest7() {
	title='shell-unsafe chars with "?" glob'
	match x\'\"\)x ?\'\"\)?
}
doTest8() {
	title='quotes in pattern: no special meaning'
	not match a \"a\"
}
doTest9() {
	title='semicolon, space, escaped regular char'
	match 'test; echo hi' '*; \e*'
}
doTest10() {
	title='backslash-escaped backslash'
	match '\' '\\'
}
doTest11() {
	title='dangling final backslash is invalid'
	match '\' '\'
	eq $? 2
}
doTest12() {
	title='backslash-escaped newline'
	match "$CCn" "\\$CCn"
}

# Control characters:
doTest13() {
	title="31 control characters"
	push cc varname
	cc=0
	while lt cc+=1 32; do
		varname=CC$(printf '%02X' "$cc")
		eval "match \"ab\${$varname}cd\" \"\\a\\b\${$varname}\\c\\d\"" || failmsg=${failmsg-}$varname' '
	done
	pop cc varname
	not isset failmsg
}

lastTest=13
