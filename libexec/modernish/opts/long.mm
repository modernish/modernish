#! /module/for/moderni/sh
#
# opts/long
#
# Add support for GNU-style --option and --option=argument long options to
# the 'getopts' shell builtin, using a new --long=<longoptstring> option.
#
# Usage: getopts [ --long=<longoptstring> ] <optstring> <varname> [ <arg> ... ]
# The <longoptstring> is analogous to the getopt builtin's <optstring>, but
# is space and/or comma separated. Each long option specification is a glob
# pattern, to facilitate spelling variants, etc. Appending one colon indicates
# the option requires an argument; appending two colons indicates the option
# may optionally be supplied with an argument. All other function arguments are
# those of the original 'getopts' built-in function. (TODO: document further.)
# In this version of long options, the = for adding an argument is mandatory.
#
# Example invocation:
#
# while getopts --long='file:,list,number:,version,help,licen[sc]e' 'f:ln:vhL' opt; do
#    case $opt in
#    ( f | -file )       opt_file=$OPTARG ;;
#    ( l | -list )       opt_list=y ;;
#    ( n | -number )     opt_filenumber=$OPTARG ;;  
#    ( v | -version )    showversion; exit ;;
#    ( h | -help )       showversion; showhelp; exit ;;
#    ( L | -licen[sc]e ) showversion; showlicense; exit ;;
#    ( '?' )             exit -u 2 ;;
#    ( * )               exit 3 'internal error' ;;
#    esac
# done
# shift $((OPTIND-1))
#
# USAGE NOTE: When there is no option to an argument, POSIX specifies that
# OPTARG must be unset, but some shells make OPTARG empty instead. This bug
# is not bad enough to block on, but don't use 'isset OPTARG' to test if
# there is an argument! Instead, use 'empty "${OPTARG-}"'.
#
# The specification for the built-in getopts function is at:
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/getopts.html
#
# How it works:
#
# This function uses the "getopts" built-in to parse both short and long
# options using technique I've invented, which works as follows. A long
# option "option" with an argument "argument", taking the form
# "--option=argument", is redefined as a short option "--" with an argument
# "option=argument". The getopts built-in readily accepts this, if we just
# add "-:" at the end of the getopts short option string to accept that
# special short option '--' plus argument. Then, to parse long options
# correctly, all this function needs to do is split $OPTARG, putting the bit
# to the left of the = in the specified option variable.
#
# Surprisingly, this techique works in every POSIX-compliant shell I've
# tested and even in the original Bourne shell (as provided by Heirloom).
#
# There is a funny but harmless side effect. In getopts, short options and
# their arguments can be separated by spaces as well as combined with other
# short options that don't have arguments. So, since we're defining a long
# option in terms of a short option "--", you would expect that you can say
# "-- option=argument", but that is blocked because "--" by itself has the
# special meaning of "stop parsing options". However, given argumentless
# short options x, y and z, you *can* say strange things like
# "-xyz-option=argument" or even "-xyz- option=argument". Hopefully, no one
# will notice. ;)
#
# --- begin license ---
# Copyright (c) 2016 Martijn Dekker <martijn@inlv.org>, Groningen, Netherlands
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
# --- end license ---

# --- Initialization: OPTIND bug test. ---

# Some shells don't support calling "getopts" from a shell function; the
# standard specifies that OPTIND remains a global variable, but when the
# getopts builtin is called from a shell function, (d)ash stops updating
# it after parsing the first option, and zsh doesn't update it at all
# because it makes OPTIND a mandatory function-local variable.
# bash, ksh93, pdksh, mksh and yash all work fine.
# (NEWS: zsh fixes this in POSIX mode as of version 5.0.8.)
#
# TODO: support matching of partial long options with redundancy checking.
#
# TODO: for shells with function-local internal getopts state (i.e. all
# Almquist derivatives, which are far too common to ignore), implement a
# complete POSIX-compatible getopts replacement that parses both short and
# long options using pure shell code.

push OPTIND OPTARG
OPTIND=1
unset -v _Msh_gO_bug

_Msh_gO_callgetopts() {
	getopts 'D:ln:vhL-:' _Msh_gO_opt "$@"
}

_Msh_gO_testfn() {
	let "OPTIND==1" || return

	_Msh_gO_callgetopts "$@"
	isset _Msh_gO_opt && identic "${_Msh_gO_opt}" D && identic "${OPTARG-}" test || return

	_Msh_gO_callgetopts "$@"
	identic "${_Msh_gO_opt}" h && empty "${OPTARG-}" || return

	_Msh_gO_callgetopts "$@"
	identic "${_Msh_gO_opt}" n && identic "${OPTARG-}" 1 || return

	_Msh_gO_callgetopts "$@"
	let "OPTIND==5" || return
}

# Don't change the test arguments in any way without changing
# the expected results in _Msh_gO_testfn() accordingly!
_Msh_gO_testfn -D 'test' -hn 1 'test' 'arguments'

if not so; then
	putln	"opts/long: On this shell, 'getopts' has a function-local internal" \
		"           state, so this module can't use a function to extend its" \
		"           functionality.${ZSH_VERSION+ (zsh 5.0.8 fixes this)}"
	_Msh_gO_bug=y
fi

unset -v _Msh_gO_opt
unset -f _Msh_gO_testfn _Msh_gO_callgetopts
pop OPTIND OPTARG

if isset _Msh_gO_bug; then
	unset -v _Msh_gO_bug
	return 2
fi


# --- THE ACTUAL THING ---

if thisshellhas BUG_UPP; then
	alias getopts='_Msh_doGetOpts "$#" ${1+"$@"}'
else
	alias getopts='_Msh_doGetOpts "$#" "$@"'
fi
_Msh_doGetOpts() {
	if not isset OPTIND; then
		die "getopts: OPTIND not set"
	# yash sets $OPTIND to two values like '1:2' so we can't validate it.
	#elif not isint $OPTIND || let "OPTIND < 0"; then
	#	die "getopts: OPTIND corrupted (value is $OPTIND)"
	fi

	# On zsh < 5.0.8, BUG_HASHVAR requires either a space after $# or braces in ${#}
	if let "$# - ($1+1) > 3" || { let "$# - ($1+1) > 2" && eval "not startswith \"\$$(( $1 + 2 ))\" '--long='"; }
	then
		# The options to parse were given on the command line,
		# so discard caller's positional parameters.
		shift "$(( $1 + 1 ))"
	elif let "$1 >= 1"; then
		# The alias passes the caller's positional parameters to the
		# function first, before any arguments to 'getopts'. Reorder the
		# parameters so the arguments to 'getopts' come first, not last.
		storeparams -f2 -t"$(( $1 + 1 ))" _Msh_gO_callersparams
		shift "$(( $1 + 1 ))"
		eval "set -- \"\$@\" ${_Msh_gO_callersparams}"
		unset -v _Msh_gO_callersparams
	else
		# The alias did not pass any positional parameters.
		shift
	fi

	# Extract --long= option (if given).
	if startswith "$1" '--long='; then
		_Msh_gO_LongOpts=${1#--long=}
		_Msh_gO_ShortOpts=$2
		_Msh_gO_VarName=$3
		shift 3
	else
		_Msh_gO_LongOpts=''
		_Msh_gO_ShortOpts=$1
		_Msh_gO_VarName=$2
		shift 2
	fi

	# zsh's 'getopts' built-in doesn't cope with OPTARG being unset
	# (which is contrary to the standard), so make sure it's set.
	OPTARG=''

	# BUG_UPP workaround, BUG_PARONEARG compatible
	let "$#" || return 1

	# Run the builtin (adding '-:' to the short opt string to parse the
	# special short option '--' plus arg) and check the results.
	command getopts "${_Msh_gO_ShortOpts}-:" "${_Msh_gO_VarName}" "$@"

	case "$?" in
	( 0 )	# don't do anything extra if it's not a long option
		if not eval "identic \"\$${_Msh_gO_VarName}\" '-'"; then
			return 0
		fi ;;
	( 1 )	return 1 ;;
	( * )	die "getopts: error from the getopts built-in command" || return ;;
	esac

	# Split long option from its argument and add leading dash.
	_Msh_gO_Opt=-${OPTARG%%=*}
	if identic "${_Msh_gO_Opt}" "-$OPTARG"; then
		unset -v OPTARG
	else
		OPTARG=${OPTARG#*=}
	fi

	# Check it against the provided list of long options.
	unset -v _Msh_gO_NoMsg _Msh_gO_Found
	push IFS -f
	set -f
	IFS=,$WHITESPACE
	for _Msh_gO_OptSpec in ${_Msh_gO_LongOpts}; do
		if identic "${_Msh_gO_OptSpec}" ':'; then
			_Msh_gO_NoMsg=y
			continue
		fi
		_Msh_gO_glob=-${_Msh_gO_OptSpec%:}
		_Msh_gO_glob=${_Msh_gO_glob%:}
		if match "${_Msh_gO_Opt}" "${_Msh_gO_glob}"; then
			_Msh_gO_Found=y
			break
		fi
	done
	pop IFS -f

	if isset _Msh_gO_Found; then
		case ${_Msh_gO_OptSpec} in
		# If the option may have an optional argument, no further
		# testing is needed.
		( *:: )
			eval "${_Msh_gO_VarName}=\${_Msh_gO_Opt}"
			;;
		# If the option requires an argument, test that it has one,
		# replicating the short options behaviour of 'getopts'.
		( *: )
			if not isset OPTARG; then
				if isset _Msh_gO_NoMsg; then
					eval "${_Msh_gO_VarName}=':'"
					OPTARG=-${_Msh_gO_OptSpec}
				else
					eval "${_Msh_gO_VarName}='?'"
					putln "${ME##*/}: option requires argument: -${_Msh_gO_Opt}" 1>&2
				fi
			else
				eval "${_Msh_gO_VarName}=\${_Msh_gO_Opt}"
			fi
			;;
		# If the option may not have an argument, test it doesn't have one,
		# replicating 'getopts' behaviour for missing mandatory argument.
		( * )
			if isset OPTARG; then
				if isset _Msh_gO_NoMsg; then
					eval "${_Msh_gO_VarName}=':'"
					OPTARG=-${_Msh_gO_OptSpec}
				else
					eval "${_Msh_gO_VarName}='?'"
					putln "${ME##*/}: option doesn't allow an argument: -${_Msh_gO_Opt}" 1>&2
				fi
			else
				eval "${_Msh_gO_VarName}=\${_Msh_gO_Opt}"
			fi
			;;
		esac
	else
		# Option not found.
		eval "${_Msh_gO_VarName}='?'"
		if isset _Msh_gO_NoMsg; then
			OPTARG=${_Msh_gO_Opt}
		else
			unset -v OPTARG
			putln "${ME##*/}: unrecognized option: -${_Msh_gO_Opt}" 1>&2
		fi
	fi

	unset -v _Msh_gO_NoMsg _Msh_gO_Found _Msh_gO_Opt _Msh_gO_OptSpec _Msh_gO_glob
	return 0
}
