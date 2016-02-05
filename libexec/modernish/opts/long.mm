#! /bin/sh
#
# modernish module: opts/long
#
# Add support for GNU-style --option and --option=argument long options to
# the 'getopts' shell builtin.
# Ref.: http://pubs.opengroup.org/onlinepubs/9699919799/utilities/getopts.html#
#
# Usage: longopts <longoptstring> <varname>
# To call immediately after getopts in the option parsing loop.
# The <longoptstring> is analogous to getopt's optstring, but is space or
# comma separated. TODO: document further
# The <varname> must be the same as in the preceding getopts call.
#
# This function employs a technique I've invented, which works as follows.
# The longopts function defines a long option "--option" with an argument
# "argument", taking the form "--option=argument", in terms of a short
# option "--" with an argument "option=argument". So the caller needs to add
# "-:" at the end of the getopts short option string to accept that special
# short option '--' plus argument. Then, to parse long options correctly,
# all this function needs to do is split $OPTARG, putting the bit to the
# left of the = in the specified option variable.
#
# Surprisingly, this techique works in every POSIX-compliant shell I've
# tested and even in the original Bourne shell (as provided by Heirloom).

longopts() {
	eq $# 2 || _msh_dieArgs longopts $# 2

	# validate varname to prevent code injection vuln with eval
	case "$2" in
	( '' | [!a-zA-Z_]* | *[!a-zA-Z0-9_]* )
		die "longopts: invalid variable name: $2" ;;
	esac

	# don't do anything if it's not a long option
	eval test "\"\$$2\" = '-'" || return 0

	unset _msh_longopts_NoMsg

	# split long option from its argument and add leading dash
	_msh_longopts_Opt="-${OPTARG%%=*}"
	if same "$_msh_longopts_Opt" = "-$OPTARG"; then
		OPTARG=''
	else
		OPTARG=${OPTARG#*=}
	fi

	# check it against the provided list of long options
	fieldsplitting save
	fieldsplitting at ",$WHITESPACE"
	for _msh_longopts_OptSpec in $1; do
		if same "$_msh_longopts_OptSpec" ':'; then
			_msh_longopts_NoMsg=y
			continue
		fi
		if not match "-${_msh_longopts_OptSpec%:}" "$_msh_longopts_Opt"; then
			continue
		fi

		# if the option requires an argument, test that it has one,
		# replicating the short options behaviour of 'getopts'
		case "$_msh_longopts_OptSpec" in
		( *: )	if empty "$OPTARG"; then
				if isset _msh_longopts_NoMsg; then
					eval "$2=':'"
					OPTARG="-$_msh_longopts_OptSpec"
				else
					eval "$2='?'"
					echo "${ME##*/}: option requires argument: -$_msh_longopts_Opt" 1>&2
				fi
				return 0
			fi
		esac
		
		eval "$2=\$_msh_longopts_Opt"
		return 0
	done
	fieldsplitting restore

	# long option not found
	eval "$2='?'"
	if isset _msh_longopts_NoMsg; then
		OPTARG=$_msh_longopts_Opt
	else
		unset OPTARG
		echo "${ME##*/}: unrecognized option: -$_msh_longopts_Opt" 1>&2
	fi
	return 0
}
