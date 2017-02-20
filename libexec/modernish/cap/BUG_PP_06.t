#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_PP_06: POSIX says that unquoted $@ initially generates as many
# fields as there are positional parameters, and then (because $@ is
# unquoted) each field is split further according to IFS. With this
# bug, the latter step is not done.
# Found on: zsh 5.0.8

set -- ab cdXef gh
push IFS
IFS='X'
set -- $@
pop IFS
case $#,${1-},${2-},${3-},${4-} in
( 4,ab,cd,ef,gh ) return 1 ;;
( 3,ab,cdXef,gh, ) ;;	# got bug
( * ) echo 'BUG_PP_06.t: internal error: undiscovered bug with unqoted $@'; return 2 ;;
esac
