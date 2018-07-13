#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_FNSUBSH: Function definitions within subshells (including command
# substitutions) are ignored if a function by the same name exists in
# the main shell, so the wrong function is executed. (Unsetting of functions
# is also ignored, as is setting/unsetting of aliases.)
# ksh93 (all current versions as of 2016) has this bug.
_Msh_testFn() { PATH=$DEFPATH command echo main; }
case $( _Msh_testFn() { PATH=$DEFPATH command echo sub; }; _Msh_testFn ) in
( main ) unset -f _Msh_testFn ;;	# bug found
( * ) unset -f _Msh_testFn; return 1 ;;
esac
