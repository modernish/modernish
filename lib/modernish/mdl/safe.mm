#! /module/for/moderni/sh
\command unalias command_not_found_handle command_not_found_handler fsplit glob 2>/dev/null
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
unset -v _Msh_safe_i _Msh_safe_k
shift	# abandon $1 = module name
while let "$#"; do
	case "$1" in
	( -i )	_Msh_safe_i=y;;
	( -k )	_Msh_safe_k=y ;;
	( -K )	_Msh_safe_k=Y ;;
	( * )	putln "safe.mm: invalid option: $1"
		return 1 ;;
	esac
	shift
done

# --- Eliminate most variable quoting headaches ---
# (allows a zsh-ish style of shell programming)

# Disable field splitting.
IFS=''

# -f: Disable pathname expansion (globbing).
set -o noglob

# --- Other safety measures ---

# -u: error out when reading an unset variable (thereby preventing
# hard-to-trace bugs with unexpected empty removal on unquoted unset
# variables, for instance, if you make a typo in a variable name).
set -o nounset

# -C: protect files from being accidentally overwritten using output
# redirection. (Use '>|' instesad of '>' to explicitly overwrite any file
# that may exist).
set -o noclobber

# If -k is given, try to die() on command not found. We know about methods
# implemented by bash, zsh and yash. Rather than doing version checking,
# just set them all, in case another shell copies this great feature :)
if isset _Msh_safe_k; then
	# Check if the shell can handle command not found.
	command_not_found_handle()  { setstatus 42; }		# bash (subshell function)
	command_not_found_handler() { setstatus 42; }		# zsh (subshell function)
	COMMAND_NOT_FOUND_HANDLER='HANDLED=y; setstatus 42';	# yash (no subshell, no function, but local HANDLED)
	PATH=/dev/null A09BB171-7AD4-4866-BED3-85D6E6A62288 2>/dev/null
	case $? in
	( 42 )	command_not_found_handler() {
			if isset MSH_NOT_FOUND_OK; then
				return 127
			else
				die "command not found: $1"
			fi
		}
		command_not_found_handle() {
			command_not_found_handler "$1"
		}
		readonly COMMAND_NOT_FOUND_HANDLER='HANDLED=y; command_not_found_handler "$1"'
		if thisshellhas ROFUNC; then
			readonly -f command_not_found_handler command_not_found_handle
		fi
		unset -v MSH_NOT_FOUND_OK _Msh_safe_k;;
	( * )	if str eq ${_Msh_safe_k} y; then
			unset -v _Msh_safe_k COMMAND_NOT_FOUND_HANDLER
			# fallthrough
		else
			putln "safe.mm: -K given, but shell does not support intercepting command not found"
			return 1
		fi ;;
	esac
fi

# --- A couple of convenience functions for fieldsplitting and globbing ---
# Primarily convenient for interactive shells. To load these in shell
# scripts, add the -i option to 'use safe'. However, for shell scripts,
# LOCAL...BEGIN...END blocks are recommended instead (see var/local.mm).

if isset -i || isset _Msh_safe_i; then

	if not isset _Msh_safe_i; then
		putln >&2 "NOTE: the safe mode is designed to eliminate quoting hell for scripts, but may" \
			"be inconvenient to use on interactive shells. Field splitting and globbing are" \
			"now disabled. Be aware that something like 'ls *.txt' now will not work by" \
			"default. However, two extra functions are available in interactive safe mode:" \
			"  - fsplit {on,off,set CHARS,save,restore,show}" \
			"  - glob {on,off,save,restore,show}" \
			"Using (subshells) is a recommended technique for interactive safe mode, e.g.:" \
			"	(glob on; ls *.txt)" \
			"[To disable this warning, add the '-i' option to 'use safe'.]"
	fi

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
				let "$#" || die "fsplit set: argument expected"
				IFS="$1"
				;;
			( 'save' )
				push IFS
				;;
			( 'restore' )
				pop IFS || die "fsplit restore: stack empty"
				;;
			( 'show' )
				if not isset IFS || str eq "$IFS" " ${CCt}${CCn}"; then
					putln "field splitting is active with default separators:" \
					      "  20  09  0a" \
					      "      \t  \n"
				elif str empty "$IFS"; then
					putln "field splitting is not active"
				else
					putln "field splitting is active with custom separators:"
					put "$IFS" | od -v -An -tx1 -c || die "fsplit: 'od' failed"
				fi
				# TODO: show field splitting settings saved on the stack, if any
				;;
			( * )
				die "fsplit: invalid argument: $1"
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
				push -f
				;;
			( 'restore' )
				pop -f || die "glob restore: stack empty"
				;;
			( 'show' )
				if isset -f
				then putln "pathname expansion is not active"
				else putln "pathname expansion is active"
				fi
				# TODO: show glob settings saved on the stack, if any
				;;
			( * )
				die "glob: invalid argument: $1"
				;;
			esac
			shift
		done
	}

fi

unset -v _Msh_safe_wAPPENDC _Msh_safe_i
