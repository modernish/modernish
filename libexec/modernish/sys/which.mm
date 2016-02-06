#! /module/for/moderni/sh

# Outputs the first path of each given command, or, if given the -a, option,
# all available paths, in the given order, according to the system $PATH.
# Exits successfully if at least one path was found for each command, or
# unsuccessfully if none were found for any given command.
#
# This implementation is a subset of both modern BSD and GNU 'which'. It is
# provided here so portable modernish programs have a consistent variant of
# 'which' at their disposal.
#
# Usage: which [ -a ] [ -s ] <programname> [ <programname> ... ]
#
# NOTE: subshell function. Settings, variables, getopts state etc. won't stick.
which() (
	set -f -u +e
	IFS=''

	unset -v opt_allpaths opt_silent
	OPTIND=1
	while command getopts 'as' opt; do case $opt in
	( a )	opt_allpaths=y ;;
	( s )	opt_silent=y ;;
	( '?' )	die || return ;;
	( * )	die "which: internal error" || return ;;
	esac; done; shift $((OPTIND-1))
	gt $# 0 || die "which: at least 1 non-option argument expected" || return

	flag_allfound=y
	for arg do
		case $arg in
		# if some path was given, search only it.
		( */* )	paths=${arg%/*}
			cmd=${arg##*/} ;;
		# if only a command was given, search all paths in $PATH
		( * )	paths=$PATH
			cmd=$arg ;;
		esac
		unset -v flag_foundthisone

		IFS=':'
		for dir in $paths; do
			if isreg -L "$dir/$cmd" && canexec "$dir/$cmd"; then
				flag_foundthisone=y
				if isset opt_silent; then
					break
				else
					print "$dir/$cmd"
					if not isset opt_allpaths; then
						break
					fi
				fi
			fi
		done
		if not isset flag_foundthisone; then
			unset -v flag_allfound
			if isset opt_silent; then
				break
			else
				print "which: no $cmd in ($paths)" 1>&2
			fi
		fi
	done
	isset flag_allfound
)
