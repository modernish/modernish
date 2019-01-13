#! /shell/capability/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# KSHARRAY: ksh93-style shell arrays (also on bash, and zsh under 'emulate sh')

# With KSHARRAY, a normal variable is identical to the first element (0) of
# the array by the same name.
( command eval '
	_Msh_test=(one two three) &&
	set -- "${_Msh_test}" &&
	let "$# == 1" &&		# blacklist yash arrays, which are very different ($# == 3)
	str eq "${_Msh_test}" one &&	# ...otherwise yash would die here (4 args to identic)
	str eq "${_Msh_test[0]}" one &&
	let "${#_Msh_test[@]}==3"'
) 2>/dev/null || return 1
