#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_OPTNOLOG: on dash, setting '-o nolog' causes "$-" to wreak havoc:
# trying to expand "$-" silently aborts parsing of an entire argument.
# This breaks modernish in various places, as you might expect.
# (The same applies to '-o debug', but we're only testing POSIX[*] here.)
#
#   [*]	"nolog: Prevent the entry of function definitions into the command
#    	history; see Command History List."
#	http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_25_03

(
	set -o nolog
	set -- "one $- two"
	! str end "$1" " two"
) 2>/dev/null || return 1
