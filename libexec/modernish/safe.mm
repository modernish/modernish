#! /module/for/moderni/sh
#
# 'use safe' loads safer shell defaults, plus utilities to facilitate
# temporary deviations from the defaults.
#
# For interactive shells (or if 'use safe' is given the '-i' option), there
# are the 'fsplit' and 'glob' functions. For shell scripts to control field
# splitting and globbing, it's recommended to use var/setlocal instead.

# ------------

unset -v _Msh_safe_b _Msh_safe_i
while gt "$#" 0; do
	case "$1" in
	( -b ) _Msh_safe_b=y ;;
	( -i ) _Msh_safe_i=y ;;
	( -bi | -ib ) _Msh_safe_b=y; _Msh_safe_i=y ;;
	( * ) print "safe.mm: invalid argument: $1"; return 1 ;;
	esac
	shift
done
if thisshellhas BUG_UPP && not isset MSH_INTERACTIVE && not isset _Msh_safe_b
then
	print 'safe.mm: This module sets -u (nounset), but this shell has BUG_UPP, a bug that' \
	      '         unjustly considers accessing "$@" and "$*" to be an error if there are' \
	      '         no positional parameters. To "use safe" in a BUG_UPP compatible way,' \
	      '         add the -b option to "use safe" and carefully write your script to' \
	      '         check that $# is greater than 0 before accessing "$@" or "$*" (even' \
	      '         implicitly as in "for var do stuff; done").' 1>&2
	return 1
fi

# --- Eliminate most variable quoting headaches ---
# (makes shell work mostly like zsh)

# Disable field splitting.
IFS=''

# Disable pathname expansion (globbing) on non-interactive shells.
if not isset MSH_INTERACTIVE; then
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
# Primarily convenient for interactive shells. To load these in shell
# scripts, add the -i option to 'use safe'. However, for shell scripts,
# setlocal/endlocal blocks are recommended instead (see further below).

if isset MSH_INTERACTIVE || isset _Msh_safe_i; then

	# fsplit:
	# Turn field splitting on (to default space+tab+newline), or off, or turn it
	# on with specified characters. Use the modernish CC* constants to
	# represent control characters. For an example of the latter, the default is
	# represented with the command:
	#
	#	fsplit at " ${CCt}${CCn}" # space, tab, newline
	#
	# Ref.: http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_06_05
	#	1. If the value of IFS is a <space>, <tab>, and <newline>, ***OR IF
	#	   IT IS UNSET***, any sequence of <space>, <tab>, or <newline>
	#	   characters at the beginning or end of the input shall be ignored
	#	   and any sequence of those characters within the input shall
	#	   delimit a field.
	#	2. If the value of IFS is null, no field splitting shall be performed.
	#
	# 'fsplit save' and 'fsplit restore' use the stack functions
	# above to gain multiple levels of save and restore; this allows safe use in
	# functions, loops, and recursion. We have to save/restore not just the
	# value, but also the set/unset state, because this determines whether field
	# splitting is active at all. The stack functions do this.

	fsplit() {
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
				gt "$#" 0 || die "fsplit at: argument expected" || return
				IFS="$1"
				;;
			( 'save' )
				push IFS || die "fsplit save: 'push' failed" || return
				;;
			( 'restore' )
				if not stackempty IFS; then
					pop IFS || die "fsplit restore: 'pop' failed" || return
				else
					die "fsplit restore: stack empty" || return
				fi
				;;
			( 'show' )
				if not isset IFS || same "$IFS" " ${CCt}${CCn}"; then
					print "field splitting is active with default separators"
				elif empty "$IFS"; then
					print "field splitting is not active"
				else
					print "field splitting is active with separators:"
					printf '%s' "$IFS" | od -v -An -tx1 -c || die "fsplit: 'od' failed" || return
				fi
				# TODO: show field splitting settings saved on the stack, if any
				;;
			( * )
				die "fsplit: invalid argument: $1" || return
				;;
			esac
			shift
		done
	}

	# Turn globbing (a.k.a. pathname expansion) on or off.
	#
	# 'glob save' and 'glob restore' use a stack to gain multiple levels
	# of save and restore; this allows safe use in functions, loops, and
	# recursion.
	glob() {
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

unset -v _Msh_safe_b _Msh_safe_i || true
