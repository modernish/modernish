#! /shell/quirk/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# QRK_EMPTPPFLD: Unquoted $@ and $* do not discard empty fields.
#
# POSIX (Section 2.5.2) says for both $@ and $*:
#   "When the [unquoted] expansion occurs in a context where field splitting
#   will be performed, any empty fields MAY be discarded and each of the
#   non-empty fields shall be further split [...]".
# (emphasis mine)
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_05_02
#
# In practice, most shells discard the empty field, so not discarding it is
# considered a quirk. (Found on yash)
#
# The description at Austin Group bug 888 indicates that the optional
# discarding behaviour may become mandated in the future.
# http://austingroupbugs.net/view.php?id=888

set -- "one" "" "three"

push IFS -f
set -f		# no globbing
unset -v IFS	# default field splitting
set -- $*	# the behaviour of unquoted $@ and $* is identical in this context
pop IFS -f

case $#,${1-},${2-},${3-} in
( 3,one,,three )  return 0 ;;	# got quirk
( 2,one,three, )  return 1 ;;
( * )	# undiscovered bug
	return 1 ;;
esac
