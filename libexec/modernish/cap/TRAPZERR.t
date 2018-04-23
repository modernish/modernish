#! /shell/capability/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# TRAPZERR: the ERR trap is an alias for the ZERR trap. (zsh on most systems)

case $(	command trap - ZERR ERR 2>/dev/null || exit
	command trap - DEBUG 2>/dev/null
	command trap ': one' ZERR
	command trap
	command trap - ERR	# does clearing ERR clear ZERR?
	command trap
     ) in
( *${CCn}* )
	return 1 ;;
( *": one"?" ZERR" )
	;;
( * )	return 1 ;;
esac
