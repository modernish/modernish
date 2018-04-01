#! /shell/capability/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# TRAPZERR: the ERR trap is an alias for the ZERR trap. (zsh on most systems)

case $(	command trap - ZERR ERR || exit
	command trap 'put one' ZERR
	command false
	command trap 'put two' ERR
	command false
     ) in
( onetwo )
	;;
( * )	return 1 ;;
esac 2>/dev/null
