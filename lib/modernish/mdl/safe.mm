#! /module/for/moderni/sh
\command unalias command_not_found_handle command_not_found_handler g s _Msh_g_help _Msh_s_help 2>/dev/null
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
# are the 's' and 'g' functions for convenient control of field splitting and
# globbing from the command line, as well as running single commands with safe
# local split and glob operations.
#
# Note: as long as zsh 5.0.8 remains supported, authors of portable scripts
# should take note of BUG_APPENDC: the `>>` appending output redirection
# operator does not create a file but errors out if it doesn't already exist.
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
	case $1 in
	( -i )	_Msh_safe_i=y;;
	( -k )	_Msh_safe_k=y ;;
	( -K )	_Msh_safe_k=Y ;;
	( -[!-]?* ) # split a set of combined options
		_Msh__o=${1#-}; shift
		while not str empty "${_Msh__o}"; do
			set -- "-${_Msh__o#"${_Msh__o%?}"}" "$@"; _Msh__o=${_Msh__o%?}	#"
		done; unset -v _Msh__o; continue ;;
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
# redirection. (Use '>|' instead of '>' to explicitly overwrite any file
# that may exist).
set -o noclobber

# If -k is given, try to die() on command not found. We know about methods
# implemented by bash, zsh and yash.
if isset _Msh_safe_k; then
	unset -v MSH_NOT_FOUND_OK
	# Check if the shell can handle command not found.
	command_not_found_handler() { return 42; }		# zsh (subshell function)
	command_not_found_handle()  { return 43; }		# bash (subshell function)
	COMMAND_NOT_FOUND_HANDLER='HANDLED=y; setstatus 44';	# yash (no subshell, no function, but local HANDLED)
	PATH=/dev/null A09BB171-7AD4-4866-BED3-85D6E6A62288 2>/dev/null
	case $? in
	( 42 )	command_not_found_handler() { isset MSH_NOT_FOUND_OK && return 127 || die "command not found: $1"; }
		thisshellhas ROFUNC && readonly -f command_not_found_handler
		unset -f command_not_found_handle
		unset -v _Msh_safe_k COMMAND_NOT_FOUND_HANDLER
		;;
	( 43 )	command_not_found_handle() { isset MSH_NOT_FOUND_OK && return 127 || die "command not found: $1"; }
		thisshellhas ROFUNC && readonly -f command_not_found_handle
		unset -f command_not_found_handler
		unset -v _Msh_safe_k COMMAND_NOT_FOUND_HANDLER
		;;
	( 44 )	COMMAND_NOT_FOUND_HANDLER='HANDLED=y; if isset MSH_NOT_FOUND_OK; then setstatus 127; '
		COMMAND_NOT_FOUND_HANDLER=${COMMAND_NOT_FOUND_HANDLER}'else die "command not found: $1"; fi'
		readonly COMMAND_NOT_FOUND_HANDLER
		unset -f command_not_found_handler command_not_found_handle
		unset -v _Msh_safe_k
		;;
	( * )	unset -f command_not_found_handle command_not_found_handler
		unset -v COMMAND_NOT_FOUND_HANDLER
		if str eq ${_Msh_safe_k} Y; then
			putln "safe.mm: -K given, but shell does not support intercepting command not found"
			unset -v _Msh_safe_k
			return 1
		fi
		unset -v _Msh_safe_k ;;
	esac
fi

# --- A couple of convenience functions for field splitting and globbing ---
# Primarily convenient for interactive shells. To load these in shell
# scripts, add the -i option to 'use safe'. However, for shell scripts,
# LOCAL...BEGIN...END blocks are recommended instead (see var/local.mm).

if isset -i || isset _Msh_safe_i; then

	if not isset _Msh_safe_i; then
		putln >&2 "NOTE: the safe mode is designed to eliminate quoting hell for scripts, but may" \
			"be inconvenient to use on interactive shells. Field splitting and globbing are" \
			"now disabled. Be aware that something like 'ls *.txt' now will not work by" \
			"default. However, two extra functions are available in interactive safe mode:" \
			"  - s [ --sep=CHARS,--on,--off,--save,--restore,--show ] [ COMMAND ]" \
			"  - g [ --nglob,--fglob,--on,--off,--save,--restore,--show ] [ COMMAND ]" \
			"Use these run a command with safe split or glob. For example, to expand '*.txt':" \
			"	g ls *.txt" \
			"Type 's --help' and 'g --help' for more information." \
			"[To disable this warning, add the '-i' option to 'use safe'.]"
	else
		unset -v _Msh_safe_i
	fi

	isset -i && use var/stack/trap

	_Msh_s_help() {
		putln "Usage: s [ OPTIONS ] [ COMMAND ]" \
			"If a COMMAND is given and safe mode is on, s runs it after performing" \
			"local field splitting on all arguments except the command name/path." \
			"Long option names may be abbreviated. Supported OPTIONS are:" \
			"--separators=CHARACTERS" \
			"	split fields by any of CHARACTERS instead of space/tab/newline" \
			"-a, --on, --activate" \
			"	activate global field splitting with given or default separators" \
			"-d, --off, --deactivate" \
			"	deactivate global field splitting" \
			"-s, --save" \
			"	push current global field splitting state on stack" \
			"-r, --restore" \
			"	pop global field splitting state from stack" \
			"--show, (no arguments)" \
			"	show current global field splitting state" \
			"--help" \
			"	show this help text"
	}

	s() {
		if let "$# == 0"; then
			set -- '--show'
		fi
		unset -v _Msh_s_sep
		while let "$#"; do
			case "$1" in
			( -- )	shift; break ;;
			( --* )	isset -i && pushtrap --nosubshell 'pop --key=_Msh_SpLiT REPLY' INT
				push --key=_Msh_SpLiT REPLY
				if str -M begin --on --activate --off --deactivate --save --restore --show \
						--separators --help "${1%%=*}"
				then
					case ${REPLY#--} in
					( separators )
						str in "$1" '=' || die "s: option requires argument: $REPLY" ;;
					( * )	str in "$1" '=' && die "s: option does not accept argument: $REPLY" ;;
					esac
					case ${REPLY#--} in
					(separators)	_Msh_s_sep=${1#*=} ;;
					(on|activate)	IFS=${_Msh_s_sep-" $CCt$CCn"} ;;
					(off|deactiv*)	IFS='' ;;
					(save)		push IFS ;;
					(restore)	pop IFS || die "s: stack empty" ;;
					(show)		put "global field splitting is "
							if not isset IFS || str eq "$IFS" " $CCt$CCn"; then
								putln "active with default separators:" \
								      "  20  09  0a" \
								      "  sp  ht  nl" \
								      "      \t  \n"
							elif str empty "$IFS"; then
								putln "not active"
							else
								putln "active with custom separators:"
								put "$IFS" | PATH=$DEFPATH command od -v -An -tx1 -ta -tc \
								|| die "s: 'od' or 'awk' failed"
							fi ;;
							# TODO: show field splitting settings saved on the stack
					(help)		_Msh_s_help ;;
					( * )		die "s: internal error" ;;
					esac
				else
					case $? in
					( 1 )	die "s: invalid option: ${1%%=*} (try --help)" ;;
					( * )	push IFS -f; set -f; IFS=$CCn; set -- $REPLY; IFS=' '; REPLY="$*"; pop IFS -f
						die "s: ambiguous option: ${1%%=*}${CCn}Did you mean: $REPLY" ;;
					esac
				fi
				pop --key=_Msh_SpLiT REPLY
				isset -i && poptrap INT ;;
			( -a )	IFS=${_Msh_s_sep-" $CCt$CCn"} ;;
			( -d )	IFS='' ;;
			( -s )	push IFS ;;
			( -r )	pop IFS || die "s: stack empty" ;;
			( -[!-]?* ) # split a set of combined options
				_Msh__o=${1#-}; shift
				while not str empty "${_Msh__o}"; do
					set -- "-${_Msh__o#"${_Msh__o%?}"}" "$@"; _Msh__o=${_Msh__o%?}	#"
				done; unset -v _Msh__o; continue ;;
			( -* )	die "s: invalid option: $1 (try --help)" ;;
			( * )	break ;;
			esac
			shift
		done
		if let "$# == 0"; then
			if isset _Msh_s_sep; then
				IFS=${_Msh_s_sep}
				unset -v _Msh_s_sep
			fi
			return
		fi
		# We have a command.
		if not isset -f || not isset IFS || not str empty "$IFS"; then
			isset -i && pushtrap "s --show; g --show" INT
			die "s: command without safe mode"
		fi
		isset -i && pushtrap --nosubshell 'IFS=""' INT
		IFS=${_Msh_s_sep-" $CCt$CCn"}
		_Msh_s_C=$1
		shift
		for _Msh_s_A do
			set -- "$@" ${_Msh_s_A}
			shift
		done
		IFS=''
		isset -i && poptrap INT
		"${_Msh_s_C}" "$@"
		eval "unset -v _Msh_s_C _Msh_s_A _Msh_s_sep; return $?"
	}

	_Msh_g_help() {
		putln "Usage: g [ OPTIONS ] [ COMMAND ]" \
			"If a COMMAND is given and safe mode is on, g runs it after performing safe" \
			"local pathname expansion on all arguments containing wildcard characters." \
			"If a result could be mistaken as an option, './' is automatically prefixed." \
			"Long option names may be abbreviated. Supported OPTIONS are:" \
			"-n, --nglob, --nullglob" \
			"	remove non-matching patterns" \
			"-f, --fglob, --failglob" \
			"	die on non-matching pattern (default)" \
			"-a, --on, --activate" \
			"	activate global pathname expansion (globbing)" \
			"-d, --off, --deactivate" \
			"	deactivate global pathname expansion (globbing)" \
			"-s, --save" \
			"	save current global pathname expansion state" \
			"-r, --restore" \
			"	restore global pathname expansion state" \
			"--show, (no arguments)" \
			"	show current global pathname expansion state" \
			"--help" \
			"	show this help text"
	}

	g() {
		if let "$# == 0"; then
			set -- '--show'
		fi
		unset -v _Msh_g_null
		while let "$#"; do
			case "$1" in
			( -- )	shift; break ;;
			( --* )	isset -i && pushtrap --nosubshell 'pop --key=_Msh_gLoB REPLY' INT
				push --key=_Msh_gLoB REPLY
				if str -M begin --on --activate --off --deactivate --save --restore --show \
						--nglob --fglob --help "${1%%=*}"
				then
					str in "$1" '=' && die "s: option does not accept argument: $REPLY"
					case ${REPLY#--} in
					(on|activate)	set +f ;;
					(off|deactiva*)	set -f ;;
					(save)		push -f ;;
					(restore)	pop -f || die "g: stack empty" ;;
					(show)		put "global pathname expansion is "
							isset -f && put "not "
							putln "active" ;;
							# TODO: show glob settings saved on the stack
					(nglob|nullgl*)	_Msh_g_null='' ;;
					(fglob|failgl*)	unset -v _Msh_g_null ;;
					(help)		_Msh_g_help ;;
					( * )		die "g: internal error" ;;
					esac
				else
					case $? in
					( 1 )	die "g: invalid option: ${1%%=*} (try --help)" ;;
					( * )	push IFS -f; set -f; IFS=$CCn; set -- $REPLY; IFS=' '; REPLY="$*"; pop IFS -f
						die "g: ambiguous option: ${1%%=*}${CCn}Did you mean: $REPLY" ;;
					esac
				fi
				pop --key=_Msh_gLoB REPLY
				isset -i && poptrap INT ;;
			( -a )	set +f ;;
			( -d )	set -f ;;
			( -s )	push -f ;;
			( -r )	pop -f || die "g: stack empty" ;;
			( -n )	_Msh_g_null= ;;
			( -f )	unset -v _Msh_g_null ;;
			( -[!-]?* ) # split a set of combined options
				_Msh__o=${1#-}; shift
				while not str empty "${_Msh__o}"; do
					set -- "-${_Msh__o#"${_Msh__o%?}"}" "$@"; _Msh__o=${_Msh__o%?}	#"
				done; unset -v _Msh__o; continue ;;
			( -* )	die "g: invalid option: $1 (try --help)" ;;
			( * )	break ;;
			esac
			shift
		done
		let "$# == 0" && unset -v _Msh_g_null && return
		# We have a command.
		if not isset -f || not isset IFS || not str empty "$IFS"; then
			isset -i && pushtrap "s --show; g --show" INT
			die "g: command without safe mode"
		fi
		isset -i && pushtrap --nosubshell 'set -f' INT
		set +f
		for _Msh_dG_A do
			case ${_Msh_dG_A} in
			( *\** | *\?* | *\[?*\]* )
				for _Msh_dG_AA in ${_Msh_dG_A}; do
					if not is present "${_Msh_dG_AA}"; then
						isset _Msh_g_null || die "no match: ${_Msh_dG_AA}"
						continue
					fi
					case ${_Msh_dG_AA} in
					( -* | +* | \( | \! )
						_Msh_dG_AA=./${_Msh_dG_AA} ;;
					esac
					set -- "$@" "${_Msh_dG_AA}"
				done
				;;
			( * )
				set -- "$@" "${_Msh_dG_A}"
				;;
			esac
			shift
		done
		set -f
		isset -i && poptrap INT
		unset -v _Msh_g_null
		"$@"
	}

	if thisshellhas ROFUNC; then
		readonly -f g s _Msh_g_help _Msh_s_help
	fi

fi
