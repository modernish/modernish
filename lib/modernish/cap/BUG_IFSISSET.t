#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.
#
# BUG_IFSISSET: Cannot test in any normal way if IFS is set. On ksh93, the only way
# to test if IFS is set or not is by analysing the shell's field splitting behaviour.
#
# Bug found on: AT&T ksh93 versions JM 93u 2011-02-08, AJM 93u+ 2012-08-01


# Save IFS: value and set/unset status. Due to the bug we're trying to detect, we can't test
# if IFS is set by any normal method. The workaround is to analyse field splitting behaviour.
case ${IFS:+n} in
( '' )	set -- "a b c"			# empty: test for default field splitting
	set -- $1
	case $# in
	( 1 )	_Msh_t_IFS='' ;;	# no field splitting: it is empty and set
	( * )	unset -v _Msh_t_IFS ;;	# default field splitting: it is unset
	esac ;;
( * )	_Msh_t_IFS=$IFS ;;		# it is set and non-empty
esac

# Detect the bug.
unset -v IFS
case ${IFS+s} in
( '' )	_Msh_test=n ;;
( s )	_Msh_test=y ;;
esac

# Restore IFS.
case ${_Msh_t_IFS+s} in
( s )	IFS=${_Msh_t_IFS}; unset -v _Msh_t_IFS ;;
( * )	unset -v IFS ;;
esac

# Return result.
case ${_Msh_test} in
( n )	return 1 ;;
esac
