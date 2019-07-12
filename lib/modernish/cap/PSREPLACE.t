#! /shell/capability/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# PSREPLACE: Search and replace strings in variables using special parameter
# substitutions with a syntax vaguely resembling sed.
# Replace one: ${var/pattern/subst}  Replace all: ${var//pattern/subst}
# NOTE: prepending ${var/#/text} and appending ${var/%/text} are
# bash/zsh/mksh only and are not supported by AT&T ksh and yash.
# For compatibility, be sure to quote the '#' and '%'!
case $(	x=ABCDEFGHIJABCDEFG a=CDE b=QXY
	eval 'y=${x/"$a"/"$b"}; z=${x//"$a"/"$b"}' &&
	PATH=$DEFPATH command echo "$y,$z") in
( ABQXYFGHIJABCDEFG,ABQXYFGHIJABQXYFG )
	;;
( * )	return 1 ;;
esac 2>|/dev/null
