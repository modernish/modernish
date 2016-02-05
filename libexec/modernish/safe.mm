#! /module/for/moderni/sh
# 'use safe' loads safer shell defaults, plus utilities to facilitate
# temporary deviations from the defaults.

# --- Eliminate most variable quoting headaches ---
# (makes shell work mostly like zsh)

# Disable field splitting.
IFS=''

# Disable pathname expansion (globbing).
if isset MSH_INTERACTIVE; then
	print 'use safe: This shell is interactive, so globbing remains enabled.'
	set +f
else
	set -f
fi

# --- Other safety measures ---

# nounset: error out when reading an unset variable (thereby preventing
# hard-to-trace bugs with unexpected empty removal on unquoted unset
# variables, for instance, if you make a typo in a variable name).
set -u

# noclobber: protect files from being accidentally overwritten using output
# redirection. (Use '>|' instesad of '>' to explicitly overwrite any file
# that may exist).
set -C


# --- A couple of convenience functions for fieldsplitting and globbing ---
# Primarily convenient for interactive shells. To load these in shell scripts,
# add the -i option to 'use safe'. However, for shell scripts,
# setlocal/endlocal blocks are recommended instead (use var/setlocal).

if isset MSH_INTERACTIVE || { eq $# 1 && same $1 -i; }; then

	# fldsplit:
	# Turn field splitting on (to default space+tab+newline), or off, or turn it
	# on with specified characters. Use the modernish CC* constants to
	# represent control characters. For an example of the latter, the default is
	# represented with the command:
	#
	#	fldsplit at " ${CCt}${CCn}" # space, tab, newline
	#
	# Ref.: http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_06_05
	#	1. If the value of IFS is a <space>, <tab>, and <newline>, ***OR IF
	#	   IT IS UNSET***, any sequence of <space>, <tab>, or <newline>
	#	   characters at the beginning or end of the input shall be ignored
	#	   and any sequence of those characters within the input shall
	#	   delimit a field.
	#	2. If the value of IFS is null, no field splitting shall be performed.
	#
	# 'fldsplit save' and 'fldsplit restore' use the stack functions
	# above to gain multiple levels of save and restore; this allows safe use in
	# functions, loops, and recursion. We have to save/restore not just the
	# value, but also the set/unset state, because this determines whether field
	# splitting is active at all. The stack functions do this.

	fldsplit() {
		if eq "$#" 0; then
			set -- 'show'
		fi
		while gt "$#" 0; do
			case "$1" in
			( 'on' )
				IFS=" ${CCt}${CCn}"
				;;
			( 'off' )
				IFS=''
				;;
			( 'at' )
				shift
				gt "$#" 0 || die "fldsplit at: argument expected"
				IFS="$1"
				;;
			( 'save' )
				push IFS || die "fldsplit save: 'push' failed" || return
				;;
			( 'restore' )
				if not stackempty IFS; then
					pop IFS || die "fldsplit restore: 'pop' failed" || return
				else
					die "fldsplit restore: stack empty" || return
				fi
				;;
			( 'show' )
				if not isset IFS || same "$IFS" " ${CCt}${CCn}"; then
					print "field splitting is active with default separators"
				elif empty "$IFS"; then
					print "field splitting is not active"
				else
					print "field splitting is active with separators:"
					printf '%s' "$IFS" | od -v -An -tx1 -c || die "fldsplit: 'od' failed" || return
				fi
				# TODO: show field splitting settings saved on the stack, if any
				;;
			( * )
				die "fldsplit: invalid argument: $1" || return
				;;
			esac
			shift
		done
	}

	# Turn globbing (a.k.a. pathname expansion) on or off.
	#
	# 'globbing save' and 'globbing restore' use a stack to gain multiple levels
	# of save and restore; this allows safe use in functions, loops, and
	# recursion.
	globbing() {
		if eq "$#" 0; then
			set -- 'show'
		fi
		while gt "$#" 0; do
			case "$1" in
			( 'on' )
				set +f
				;;
			( 'off' )
				set -f
				;;
			( 'save' )
				push -f || die "globbing save: 'push' failed" || return
				;;
			( 'restore' )
				if not stackempty -f; then
					pop -f || die "globbing restore: 'pop' failed" || return
				else
					die "globbing restore: stack empty" || return
				fi
				;;
			( 'show' )
				case "$-" in
				( *f* )	print "pathname expansion is not active" ;;
				( * )	print "pathname expansion is active" ;;
				esac
				# TODO: show globbing settings saved on the stack, if any
				;;
			( * )
				die "globbing: invalid argument: $1"
				;;
			esac
			shift
		done
	}

fi
