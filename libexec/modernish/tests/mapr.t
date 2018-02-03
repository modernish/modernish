#! test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# Regression tests for var/mapr
use var/mapr
use var/string

doTest1() {
	foo=
	foo() {
		push IFS
		IFS=$CCn
		foo=$foo"$*"$CCn  # quote "$*" for BUG_PP_* compat
		pop IFS
	}
	title='read all the lines of a text file'
	mapr foo < $MSH_PREFIX/libexec/modernish/safe.mm || return 1
	trim foo $CCn
	identic $foo $(cat $MSH_PREFIX/libexec/modernish/safe.mm)
}

lastTest=1
