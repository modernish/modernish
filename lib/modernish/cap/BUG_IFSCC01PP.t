#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_IFSCC01PP: if IFS contains the ^A ($CC01) control character, the
# expansion of "$@" (even quoted) is gravely corrupted, completely breaking the
# library. Two variants, found on bash 4.0-4.3 and bash <= 3.2 respectively.

set -- one two three
push IFS
IFS=$CC01
set -- "$@"
IFS=	# unbreak the library
pop IFS
case ${1-},${2-},${3-},${4-},${5-},${6-},${7-},${8-} in
( ,,o,,n,,e${CC7F}, | one${CC01}two${CC01}three,,,,,,, )
	;;
( * )	return 1 ;;
esac
