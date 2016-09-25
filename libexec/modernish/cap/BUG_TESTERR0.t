#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_TESTERR0: mksh: 'test'/'[' exits successfully (exit status 0) if
# an invalid argument is given to an operator. (mksh R52 fixes this)
# (zsh 4.1.1 needs 'eval' here to stop main shell from exiting on this error)
eval '[ 123 -eq 1XX ]' 2>| /dev/null
case $? in
( 0 ) ;;
( * ) return 1 ;;
esac
