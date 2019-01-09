#! /module/for/moderni/sh
\command unalias fsplit glob 2>/dev/null
#
# 'use safe' loads safer shell defaults, plus utilities to facilitate
# temporary deviations from the defaults.
#
# 'use safe' does the following:
# - IFS='': Disable field splitting.
# - set -o noglob: Disable globbing. This is set on non-interactive shells only.
#	(The above two render most quoting of variable names unnecessary.
#	Only empty removal remains as a potential issue.)
# - set -o nounset: block on reading unset variables. This catches many bugs and typos.
#	However, you have to initialize variables before using them.
# - set -o noclobber: block on overwriting existing files using redirection.
#
# Take note of the safe split & glob operators in var/local and var/loop/for
# which help make working in this mode practical and straightforward. No
# more quoting, split or glob headaches!
#
# For interactive shells (or if 'use safe' is given the '-i' option), there
# are the 'fsplit' and 'glob' functions for convenient control of field
# splitting and globbing from the command line. For shell programs to
# temporarily enable these, it's recommended to use var/local instead;
# see there for documentation.
#
# Note: as long as zsh 5.0.8 remains supported, authors of portable scripts
# should take note of BUG_APPENDC: the `>>` appending output redirection
# opereator does not create a file but errors out if it doesn't already exist.
# To work around BUG_APPENDC, you could set this function and call it before
# every use of the '>>' operator where the file might not exist:
# Workaround_APPENDC() {
#        if thisshellhas BUG_APPENDC && not is -L present "$1"; then
#                : > "$1"
#        fi
# }
#
# --- begin license ---
# Copyright (c) 2018 Martijn Dekker <martijn@inlv.org>, Groningen, Netherlands
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# --- end license ---

# ------------
unset -v _Msh_safe_i
shift	# abandon $1 = module name
while let "$#"; do
	case "$1" in
	( -i )
		_Msh_safe_i=y
		;;
	( * )
		putln "safe.mm: invalid option: $1"
		return 1
		;;
	esac
	shift
done

# --- Eliminate most variable quoting headaches ---
# (allows a zsh-ish style of shell programming)

# Disable field splitting.
IFS=''

# -f: Disable pathname expansion (globbing) on non-interactive shells.
not isset -i && set -o noglob

# --- Other safety measures ---

# -u: error out when reading an unset variable (thereby preventing
# hard-to-trace bugs with unexpected empty removal on unquoted unset
# variables, for instance, if you make a typo in a variable name).
set -o nounset

# -C: protect files from being accidentally overwritten using output
# redirection. (Use '>|' instesad of '>' to explicitly overwrite any file
# that may exist).
set -o noclobber


# --- A couple of convenience functions for fieldsplitting and globbing ---
# Primarily convenient for interactive shells. To load these in shell
# scripts, add the -i option to 'use safe'. However, for shell scripts,
# LOCAL...BEGIN...END blocks are recommended instead (see var/local.mm).

if isset -i || isset _Msh_safe_i; then
	use var/stack/extra/stackempty

	# fsplit:
	# Turn field splitting on (to default space+tab+newline), or off, or turn it
	# on with specified characters. Use the modernish CC* constants to
	# represent control characters. For an example of the latter, the default is
	# represented with the command:
	#
	#	fsplit set " ${CCt}${CCn}" # space, tab, newline
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
		if let "$# == 0"; then
			set -- 'show'
		fi
		while let "$#"; do
			case "$1" in
			( 'on' )
				IFS=" ${CCt}${CCn}"
				;;
			( 'off' )
				IFS=''
				;;
			( 'set' )
				shift
				let "$#" || die "fsplit set: argument expected" || return
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
				if not isset IFS || str id "$IFS" " ${CCt}${CCn}"; then
					putln "field splitting is active with default separators:" \
					      "  20  09  0a" \
					      "      \t  \n"
				elif str empty "$IFS"; then
					putln "field splitting is not active"
				else
					putln "field splitting is active with custom separators:"
					put "$IFS" | od -v -An -tx1 -c || die "fsplit: 'od' failed" || return
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
		if let "$# == 0"; then
			set -- 'show'
		fi
		while let "$#"; do
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
				if isset -f
				then putln "pathname expansion is not active"
				else putln "pathname expansion is active"
				fi
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

unset -v _Msh_safe_wAPPENDC _Msh_safe_i
