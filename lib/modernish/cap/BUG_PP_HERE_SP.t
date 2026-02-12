#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PP_HERE_SP: $* in a here-document always uses a space as the output
# field separator, regardless of IFS. ($* is specified to use the first
# character of $IFS as the output field separator in all quoted or scalar
# contexts.) Found on: ksh93 before 93u+m/1.0.11

case $(
	set a '' b '' c
	IFS=/
	PATH=$DEFPATH command cat <<-EOF
		$*
	EOF
) in
( 'a  b  c' )
	return 0 ;;
esac
return 1  # no bug, or not this bug
