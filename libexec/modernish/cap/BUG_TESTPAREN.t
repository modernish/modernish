#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_TESTPAREN: Incorrect parsing of unary test/[ operators (-n, -z, -e, etc.)
# with values '(', ')' or '!' in zsh 5.0.6 and 5.0.7. This means test/[ cannot
# test for non-emptiness of values that may be '(', ')' or '!' or for the
# existence of files with those exact names. This can make scripts that process
# arbitrary data (e.g. the shellquote function) take the wrong action unless
# workarounds are implemented or modernish equivalents are used instead.
# Workarounds:
# - Instead of [ -z "$var" ], use one of:
#	empty "$var"		# the modernish way
#	let "! ${#var}"		# test length of value
#	[ -z "${var:+n}" ]	# the only possible values: 'n' or empty
#				# (but circumvents 'set -o nounset' ('set -u'))
# - Instead of [ -n "$var" ], use one of:
#	not empty "$var"
#	let "${#var}"
#	[ -n "${var:+n}" ]
! {
	[ -n '(' ] &&
	[ -n ')' ] &&
	[ -n '!' ]
} 2>| /dev/null
