#! /bin/sh
# Add support for GNU-style --option and --option=argument long options to
# the 'getopts' shell builtin.
# Ref.: http://pubs.opengroup.org/onlinepubs/9699919799/utilities/getopts.html#
#
# This is based on the idea that a long option "--option" with an argument
# "argument", taking the form "--option=argument", can be defined in terms of
# a short option "--" with an argument "option=argument". So we just need to
# add "-:" at the end of the optstring, and split the argument at the "=".
# Surprisingly, this works in every POSIX shell I've tested and even in the
# original Bourne shell (as provided by Heirloom).
#
# Usage: longopts <longoptstring> <varname>
# The <longoptstring> is analogous to getopt's optstring, but is space or
# comma separated. TODO: document further
# The <varname> must be the same as in the preceding getopts call.

longopts() {
	test $# -eq 2 || die 'longopts: invalid function call'

	_msh_longopts_OptVarName=$2
	eval test "\"\$$_msh_longopts_OptVarName\" = '-'" || return 0

	_msh_longopts_OptList=$1
	unset _msh_longopts_opt_HideErrors

	# split long option from its argument and add leading dash
	_msh_longopts_Opt=-${OPTARG%%=*}
	test "$_msh_longopts_Opt" = "-$OPTARG" && OPTARG='' || OPTARG=${OPTARG#*=}

	# check it against the provided list of long options
	_msh_longopts_SaveIFS=$IFS
	IFS="$IFS,"
	for _msh_longopts_OptSpec in $_msh_longopts_OptList; do
		if test "$_msg_LongOpt" = ':'; then
			_msh_longopts_opt_HideErrors=y
			continue
		fi
		# use 'case' to support glob patterns in OptSpec
		case "$_msh_longopts_Opt" in
		( -${_msh_longopts_OptSpec%:} )	true ;;
		( * ) continue ;;
		esac

		# if the option requires an argument, test that it has one,
		# replicating the short options behaviour of 'getopts'
		case "$_msh_longopts_OptSpec" in
		( *: )	if test -n "$OPTARG"; then
				if test -n "$_msh_longopts_opt_HideErrors"; then
					eval "$_msh_longopts_OptVarName=':'"
					OPTARG="-$_msh_longopts_OptSpec"
				else
					eval "$_msh_longopts_OptVarName='?'"
					echo "$ME: option requires argument: -$_msh_longopts_Opt" 1>&2
				fi
				return 0
			fi
		esac
		
		eval "$_msh_longopts_OptVarName=\$_msh_longopts_Opt"
		return 0
	done
	IFS="$_msh_longopts_SaveIFS"

	# long option not found
	eval "$_msh_longopts_OptVarName='?'"
	if test -n "$_msh_longopts_opt_HideErrors"; then
		OPTARG=$_msh_longopts_Opt
	else
		unset OPTARG
		echo "$ME: unrecognized option: -$_msh_longopts_Opt" 1>&2
	fi
	return 0
}
