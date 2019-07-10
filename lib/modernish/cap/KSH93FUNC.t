#! /shell/capability/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# KSH93FUNC: define ksh-style shell functions with the 'function' keyword,
# supporting local variables with static scoping using the 'typeset' builtin.
# NOTE: The superfluous '()' must NOT be included; ksh doesn't accept it.
# This feature test was based on Q28 at http://kornshell.com/doc/faq.html

thisshellhas --rw=function --bi=typeset || return 1
(eval 'function _Msh_testFn { :; }') 2>/dev/null || return 1

eval '
	function _Msh_testFn {
		_Msh_test=${_Msh_test2}
	}
	function _Msh_testFn2 {
		typeset _Msh_test2=local || return
		_Msh_testFn
	}' \
&& _Msh_test2=global \
&& _Msh_test='' \
&& _Msh_testFn2 || return 2

unset -v _Msh_test2
unset -f _Msh_testFn _Msh_testFn2

case ${_Msh_test} in
( global )	return 0 ;;	# static scoping (KSH93FUNC)
( local )	return 1 ;;	# dynamic scoping (KSH88FUNC)
( * )		return 2 ;;
esac
