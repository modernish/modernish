#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_TESTILNUM: On dash (up to 0.5.8), giving an illegal number to 'test -t'
# or '[ -t' causes some kind of corruption so the next 'test'/'[' invocation
# fails with an "unexpected operator" error even if it's legit. This affects
# checking the exit status of the previous 'test' with 'test'. After the
# corrupted invocation, 'test' will function normally again. So isonterminal()
# needs a workaround with 'case' and a dummy invocation of 'test' (see there).
{
	PATH=$DEFPATH command test -t 12323454234578326584376438	# "illegal number"
	PATH=$DEFPATH command test "$?" -gt 1				# trigger bug
} 2>| /dev/null
case $? in
( 0 | 1 ) return 1 ;;
( * )     return 0 ;;
esac
