#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_NOCHCLASS: character [:classes:] within bracket [expressions] are not
# supported in glob patterns. (pdksh, mksh, and family, except OpenBSD ksh)
#	On OpenBSD and NetBSD, the C globbing function fnmatch(3) is broken:
#	it has character class support, but negated character classes like
#	[![:space:]] don't work. This affects the dash shell in OpenBSD ports
#	which is configured to use fnmatch(3). Class this as same bug since
#	buggy character classes should not be considered reliable at all.
# Ref.: http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_13_01
#   and http://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap09.html#tag_09_03_05
case x in
( [[:alnum:]] )
	case x in
	( [![:space:]] ) return 1 ;;
	# positive: fnmatch(3) on OpenBSD 5.8
	esac ;;
# positive: pdksh/mksh/etc (but not OpenBSD ksh)
esac
