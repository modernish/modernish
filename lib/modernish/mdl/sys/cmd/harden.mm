#! /module/for/moderni/sh
\command unalias harden trace _Msh_harden_isSig _Msh_harden_traceInit 2>/dev/null

# sys/cmd/harden: modernish's replacement for 'set -e' (errexit)
#
# Function that installs a function to harden commands by testing their exit
# status against values indicating error or system failure. Upon failure,
# 'harden' calls 'die', so it will reliably halt program execution, even if
# the failure occurred within a subshell (for instance, in a pipe construct
# or command substitution). Also supports highlighted tracing of the command.
#
# Usage: harden [ -f <funcname> ] [ -[cSpXtPE] ] [ -e <testexpr> ] \
#	[ <var=value> ... ] [ -u <var> ... ] <cmdname/path> [ <arg> ... ]
#
# The <testexpr> is like a shell arithmetic expression, with the binary
# operators '==' '!=' '<=' '>=' '<' '>' turned into unary operators.
# Everything else is the same, including && and || and parentheses.
# What exit status indicates failure depends on the command. For standard
# commands, refer to the POSIX standard. For others, see their manual pages.
#
# <var=value> assignments cause corresponding environment variables to be
# exported with the values indicated for the duration of the command.
# Assignments override corresponding unset (-u) options, even subsequent ones.
#
# Options:
#	-f: Harden the command as the function with name <funcname> instead
#	    of a name identical to <cmdname/path>.
#	-c: One-time hardening. Instead of setting a shell function, harden
#	    and run <cmdname/path> immediately. Cannot be used with -f.
#	-S: Split <cmdname/path> by comma; use the first found. Requires -f.
#	-p: Use system default path instead of current $PATH to find
#	    external commands (akin to POSIX 'command -p').
#	    When given twice, or if <cmdname/path> is a shell function,
#	    also export PATH=$DEFPATH before running <cmdname/path>.
#	-X: Bypass builtins, always use external command.
#	-P: Do not die if the command is killed by a broken pipe.
#	-t: Trace the command (uses file descriptor 9).
#	-e: Specify exit status test expression as explained above.
#	    Defaults to '>0'.
#	-E: Die if the command writes anything to standard error.
#	    (Causes the command to be run in a subshell.)
#	-u: Unset a shell or environment variable for the duration of the command.
#	    (Causes the command to be run in a subshell.)
#
# A 'trace' shortcut function is also provided that is equivalent to:
#	harden -t -P -e '>125 && !=255' <command>
# Traces the command while providing minimal hardening against system errors.
#
# Usage examples:
#	harden -e '> 1' grep			# grep fails on exit status > 1
#	harden -e '>= 2' grep			# equivalent to the above
#	harden -e '==1 || >2' gzip		# 1 and >2 are errors, but 2 isn't (see 'man gzip')
#	harden -f findWord -Pe '>1' grep -w	# hardened function 'findWord' uses 'grep -w', tolerating SIGPIPE
#	trace cp				# equivalent to: harden -t -P -e '>125 && !=255' cp
#
# --- begin license ---
# Copyright (c) 2019 Martijn Dekker <martijn@inlv.org>, Groningen, Netherlands
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

use sys/cmd/extern
use var/shellquote

unset -v _Msh_Ht_R _Msh_Ht_y _Msh_Ht_r _Msh_Ht_b  # for storing (t)erminal codes for (t)racing
unset -v _Msh_H_C  # function name for error messages (default: 'harden')
harden() {
	_Msh_H_C=${_Msh_H_C-harden}
	# ___begin option & assignment argument parser____
	unset -v _Msh_Ho_P _Msh_Ho_t _Msh_Ho_c _Msh_Ho_S _Msh_Ho_X _Msh_Ho_e _Msh_Ho_f _Msh_Ho_u _Msh_H_VA
	_Msh_Ho_p=0	# count how many times '-p' was specified
	while	case ${1-} in
		( [!-]*=* ) # environment variable assignment
			str isvarname "${1%%=*}" || break
			isset -r "${1%%=*}" && die "${_Msh_H_C}: read-only variable: ${1%%=*}"
			shellquote _Msh_H_QV="${1#*=}"
			_Msh_H_VA=${_Msh_H_VA:+$_Msh_H_VA }${1%%=*}=${_Msh_H_QV}
			unset -v _Msh_H_QV ;;
		( -[!-]?* ) # split a set of combined options
			_Msh_Ho__o=$1
			shift
			while _Msh_Ho__o=${_Msh_Ho__o#?} && not str empty "${_Msh_Ho__o}"; do
				_Msh_Ho__a=-${_Msh_Ho__o%"${_Msh_Ho__o#?}"} # "
				push _Msh_Ho__a
				case ${_Msh_Ho__o} in
				( [euf]* ) # split optarg
					_Msh_Ho__a=${_Msh_Ho__o#?}
					not str empty "${_Msh_Ho__a}" && push _Msh_Ho__a && break ;;
				esac
			done
			while pop _Msh_Ho__a; do
				set -- "${_Msh_Ho__a}" "$@"
			done
			unset -v _Msh_Ho__o _Msh_Ho__a
			continue ;;
		( -[cSXtPE] )
			eval "_Msh_Ho_${1#-}=''" ;;
		( -p )	let "_Msh_Ho_p += 1" ;;
		( -[ef] )
			let "$# > 1" || die "${_Msh_H_C}: $1: option requires argument"
			eval "_Msh_Ho_${1#-}=\$2"
			shift ;;
		( -u )	let "$# > 1" || die "${_Msh_H_C}: $1: option requires argument"
			str isvarname "$2" || die "${_Msh_H_C} -u: invalid variable name: $2"
			_Msh_Ho_u=${_Msh_Ho_u:+$_Msh_Ho_u }$2
			shift ;;
		( -- )	shift; break ;;
		( -* )	die "${_Msh_H_C}: invalid option: $1" ;;
		( * )	break ;;
		esac
	do
		shift
	done
	# ^^^end option & assignment argument parser^^^

	case $# in
	( 0 )	die "${_Msh_H_C}: command expected${CCn}" \
			"usage: harden [ -f <funcname> ] [ -[cSpXtPE] ] [ -e <testexpr> ] \\${CCn}" \
			"${CCt}[ <var=value> ... ] [ -u <var> ... ] <cmdname/path> [ <arg> ... ]" || return ;;
	esac

	if isset _Msh_Ho_S && ! isset _Msh_Ho_f; then
		die "harden: -S requires -f"
	fi

	if isset _Msh_Ho_c; then
		if isset _Msh_Ho_f; then
			die "harden: -c cannot be used with -f"
		fi
		_Msh_Ho_f="_Msh_harden_tmp"	# temp function name
	elif ! isset _Msh_Ho_f; then
		_Msh_Ho_f=$1
	fi

	# Determine and check the canonical name or path of the command.
	push IFS -f PATH
	let "_Msh_Ho_p > 0" && PATH=$DEFPATH
	set -f
	IFS=${_Msh_Ho_S+,}  # split by comma if -S
	if isset _Msh_Ho_X; then
		for _Msh_H_cmd in $1; do
			_Msh_H_cmd=$(extern -v -- "${_Msh_H_cmd}") && break
		done
	else
		for _Msh_H_cmd in $1; do
			# POSIX says 'command -v' outputs an /absolute/pathname for regular built-ins; override this.
			thisshellhas "--bi=${_Msh_H_cmd}" && break
			_Msh_H_cmd=$(command unalias "${_Msh_H_cmd}" 2>/dev/null; command -v -- "${_Msh_H_cmd}") && break
		done
	fi
	pop IFS -f PATH
	case ${_Msh_H_cmd} in
	( '' )	if let "_Msh_Ho_p > 0"; then
			die "${_Msh_H_C}: ${_Msh_Ho_X+external }command${_Msh_Ho_S+s} not found in system default path: '$1'"
		else
			die "${_Msh_H_C}: ${_Msh_Ho_X+external }command${_Msh_Ho_S+s} not found: '$1'"
		fi ;;
	esac
	case ${_Msh_Ho_f} in
	(\!|\{|\}|case|do|done|elif|else|\esac|fi|for|if|in|then|until|while \
	|break|:|continue|.|eval|exec|exit|export|readonly|return|set|shift|times|trap|unset)
		die "${_Msh_H_C}: can't harden POSIX reserved word or special builtin '${_Msh_Ho_f}'" ;;
	( command | getopts )
		die "${_Msh_H_C}: can't harden the '${_Msh_Ho_f}' builtin" ;;
	( '' | [0123456789]* | *[!"$ASCIIALNUM"_]* )
		die "${_Msh_H_C}: invalid shell function name: ${_Msh_Ho_f}"
		;;
	esac
	if thisshellhas "--rw=${_Msh_Ho_f}"; then
		die "${_Msh_H_C}: can't harden reserved word '${_Msh_Ho_f}'"
	elif command alias "${_Msh_Ho_f}" >/dev/null 2>&1; then
		die "${_Msh_H_C}: function name '${_Msh_Ho_f}' conflicts with alias '${_Msh_Ho_f}'"
	elif ! isset _Msh_Ho_c; then
		if isset -f "${_Msh_Ho_f}"; then
			die "${_Msh_H_C}: shell function already exists: ${_Msh_Ho_f}"
		fi
		if thisshellhas "--bi=${_Msh_Ho_f}"; then
			# check if builtin is overrideable
			(eval "${_Msh_Ho_f}() { :; }") 2>/dev/null || die "${_Msh_H_C}: can't harden '${_Msh_Ho_f}'"
		fi
	fi

	# Fix the command name/path so that it will always work, regardless of subsequent
	# changes to the current working directory, $PATH, shell functions, or aliases.
	case ${_Msh_H_cmd} in
	( */* )	case ${_Msh_H_cmd} in
		( /* )  ;;
		( * )	# Relative path name: make absolute
			_Msh_E=$(command cd "${_Msh_H_cmd%/*}" &&
				command pwd &&
				put X) || die "${_Msh_H_C}: internal error"
			_Msh_H_cmd=${_Msh_E%${CCn}X}/${_Msh_H_cmd##*/} ;;
		esac
		shellquote _Msh_H_cmd
		if isset _Msh_Ho_u || isset _Msh_Ho_E; then
			# command will be run from a subshell
			_Msh_H_cmd="exec ${_Msh_H_cmd}"
		fi
		# two '-p' options: also export PATH=$DEFPATH for this command
		if let "_Msh_Ho_p > 1"; then
			_Msh_H_VA=${_Msh_H_VA:+$_Msh_H_VA }PATH=\"\$DEFPATH\"
		fi ;;
	( * )	if command alias "${_Msh_H_cmd}" >/dev/null 2>&1; then
			# Hardening aliases is too risky, as they may contain any combination of shell grammar.
			die "${_Msh_H_C}: aliases are not supported: ${_Msh_H_cmd}"
		elif thisshellhas "--rw=${_Msh_H_cmd}"; then
			die "${_Msh_H_C}: can't harden reserved word '${_Msh_H_cmd}'"
		elif	push PATH
			let "_Msh_Ho_p > 0" && PATH=$DEFPATH
			thisshellhas "--bi=${_Msh_H_cmd}"
			pop --keepstatus PATH
		then
			_Msh_H_cmd2=$(
				unset -f "${_Msh_H_cmd}" 1>&1 &&  # BUG_FNSUBSH workaround
				let "_Msh_Ho_p > 0" && PATH=$DEFPATH
				command -v "${_Msh_H_cmd}")
			case ${_Msh_H_cmd2} in
			( '' )	die "${_Msh_H_C}: builtin not found: ${_Msh_H_cmd}" ;;
			( /* )	# builtin associated with a path (yash): make sure yash can find it even after PATH changes
				_Msh_H_cmdP=${_Msh_H_cmd2%/*}
				case ${_Msh_H_cmdP} in ( '' ) _Msh_H_cmdP=/ ;; esac
				_Msh_H_cmd2=${_Msh_H_cmd2##*/}
				case ${_Msh_H_cmd2} in ( '' ) die "${_Msh_H_C}: internal error" ;; esac
				shellquote _Msh_H_cmdP
				_Msh_H_VA=${_Msh_H_VA:+$_Msh_H_VA }PATH=${_Msh_H_cmdP}
				unset -v _Msh_H_cmdP ;;
			esac
			case ${_Msh_H_cmd2} in
			( -* )	shellquote _Msh_H_cmd2; _Msh_H_cmd="command -- ${_Msh_H_cmd2}" ;;
			( * )	shellquote _Msh_H_cmd2; _Msh_H_cmd="command ${_Msh_H_cmd2}" ;;
			esac
			unset -v _Msh_H_cmd2
		elif isset -f "${_Msh_H_cmd}"; then
			# Hardening shell functions has insufficient use case and too many complications. Bypass or die.
			if _Msh_H_cmd2=$(
				let "_Msh_Ho_p > 0" && PATH=$DEFPATH
				extern -v "${_Msh_H_cmd}")
			then
				_Msh_H_cmd=${_Msh_H_cmd2}
				unset -v _Msh_H_cmd2
			else
				die "${_Msh_H_C}: hardening shell functions is not supported: ${_Msh_H_cmd}"
			fi
		else	# this should never happen
			die "${_Msh_H_C}: internal error"
		fi ;;
	esac

	# add any extra command arguments (e.g. options)
	shift
	for _Msh_E do
		shellquote _Msh_E
		_Msh_H_cmd=${_Msh_H_cmd}\ ${_Msh_E}
	done

	# if caller asked to trace the hardened command, store relevant commands in option variable _Msh_Ho_t
	if isset _Msh_Ho_t; then
		_Msh_harden_traceInit
	fi

	# command to store command + positional parameters shellquoted in _Msh_P
	_Msh_H_spp='_Msh_P=
		for _Msh_A in '"${_Msh_H_cmd}"' "$@"; do
			\shellquote _Msh_A
			\let "${#_Msh_P} + ${#_Msh_A} >= 512" && _Msh_P="${_Msh_P} (TRUNCATED)" && \break
			_Msh_P=${_Msh_P}${_Msh_P:+" "}${_Msh_A}
		done
		\unset -v _Msh_A'

	# add hardening function's positional parameters as arguments to the real command
	_Msh_H_cmd=${_Msh_H_cmd}' "$@"'

	# If we have variables to export or unset, and/or the command needs a subshell, add them now.
	if isset _Msh_Ho_u || isset _Msh_Ho_E; then
		# We have to run it in a ( subshell ) with any indicated variables unset and/or exported.
		_Msh_E=${_Msh_Ho_u:+unset -v $_Msh_Ho_u; }${_Msh_H_VA:+export $_Msh_H_VA; }
		if isset _Msh_Ho_E; then
			# Capture standard error and die if anything is written to it.
			_Msh_H_cmd="{ _Msh_e=\$(set +x; ${_Msh_E}${_Msh_H_cmd} 2>&1 1>&9); } 9>&1 && case \${_Msh_e} in (?*) ! : ;; esac"
			_Msh_Ho_E="case \${_Msh_e} in (?*) die \"${_Msh_Ho_f}: command wrote error: \${_Msh_P}\${CCn}\${_Msh_e}\" ;; esac"
		else
			_Msh_H_cmd="( ${_Msh_E}${_Msh_H_cmd} )"
		fi
		# ...for tracing and error messages:
		shellquote _Msh_E="( ${_Msh_E}"
		_Msh_H_spp="${_Msh_H_spp} && _Msh_P=${_Msh_E}\${_Msh_P}' )'"
	elif isset _Msh_H_VA; then
		# If it's a builtin or external command, and we have nothing to unset, we can use
		# the shell grammar's mechanism for temporarily assigning variables to export.
		_Msh_E="${_Msh_H_VA} "
		_Msh_H_cmd="${_Msh_E}${_Msh_H_cmd}"
		# ...for tracing and error messages:
		shellquote _Msh_E
		_Msh_H_spp="${_Msh_H_spp} && _Msh_P=${_Msh_E}\${_Msh_P}"
	fi

	# determine status checking method and set hardening function
	if	case ${_Msh_Ho_e='>0'} in
		( '>0' | '> 0' | '>=1' | '>= 1' | '!=0' | '!= 0' ) ;;
		( * ) ! : ;;
		esac &&
		! isset _Msh_Ho_P
	then	# For efficiency, handle a simple non-zero check specially.
		if isset _Msh_Ho_t; then
			eval "${_Msh_Ho_f}() {
				${_Msh_H_spp}
				${_Msh_Ho_t}
				${_Msh_H_cmd} && unset -v _Msh_P${_Msh_Ho_E+ _Msh_e} || {
					_Msh_E=\$?
					if _Msh_harden_isSig \"\${_Msh_E}\"; then
						_Msh_P=\"killed by SIG\$REPLY: \${_Msh_P}\"
					fi
					${_Msh_Ho_E-}
					die \"${_Msh_Ho_c-${_Msh_Ho_f}: }failed with status \${_Msh_E}: \${_Msh_P}\"
					eval \"unset -v _Msh_P _Msh_E${_Msh_Ho_E+ _Msh_e}; return \${_Msh_E}\"
				}
			}${CCn}"
		else
			eval "${_Msh_Ho_f}() {
				${_Msh_H_cmd}${_Msh_Ho_E+ && unset -v _Msh_e} || {
					_Msh_E=\$?
					${_Msh_H_spp}
					if _Msh_harden_isSig \"\${_Msh_E}\"; then
						_Msh_P=\"killed by SIG\$REPLY: \${_Msh_P}\"
					fi
					${_Msh_Ho_E-}
					die \"${_Msh_Ho_c-${_Msh_Ho_f}: }failed with status \${_Msh_E}: \${_Msh_P}\"
					eval \"unset -v _Msh_P _Msh_E${_Msh_Ho_E+ _Msh_e}; return \${_Msh_E}\"
				}
			}${CCn}"
		fi
	else	# Translate the status check expression to an arithmetic expression:
		# unary operators become binary operators with _Msh_E on the left hand
		case ${_Msh_Ho_e} in
		( =[!=]* | *[!!\<\>=]=[!=]* | *[%*/+-]=* | *--* | *++* )
			die "${_Msh_H_C}: assignment not allowed in status expression: '${_Msh_Ho_e}'" ;;
		( *[=\<\>]* ) ;;
		( * )	die "${_Msh_H_C}: unary comparison operator required in status expression: '${_Msh_Ho_e}'" ;;
		esac
		_Msh_H_expr=${_Msh_Ho_e}
		for _Msh_H_c in '<' '>' '==' '!='; do
			# use a temporary variable to avoid an infinite loop when
			# replacing all of one character by one or more of itself
			# (algorithm from 'replacein' in var/string.mm)
			_Msh_H_nwex=${_Msh_H_expr}
			_Msh_H_expr=
			while str in "${_Msh_H_nwex}" "${_Msh_H_c}"; do
				_Msh_H_expr=${_Msh_H_expr}${_Msh_H_nwex%%"${_Msh_H_c}"*}\(_Msh_E\)${_Msh_H_c}
				_Msh_H_nwex=${_Msh_H_nwex#*"${_Msh_H_c}"}
			done
			_Msh_H_expr=${_Msh_H_expr}${_Msh_H_nwex}
		done
		unset -v _Msh_H_nwex _Msh_H_c
		if isset _Msh_Ho_P; then
			_Msh_H_expr="(${_Msh_H_expr}) && _Msh_E!=$SIGPIPESTATUS"
		fi
		_Msh_E=0
		( : "$((${_Msh_H_expr}))" ) 2>/dev/null || die "${_Msh_H_C}: invalid status expression: '${_Msh_Ho_e}'"
		let "${_Msh_H_expr}" && die "${_Msh_H_C}: success means failure in status expression: ${_Msh_Ho_e}"

		# Set the hardening function.
		isset _Msh_Ho_E && _Msh_H_expr=\(${_Msh_H_expr}') || ${#_Msh_e}>0'
		_Msh_H_expr=\"${_Msh_H_expr}\"
		if isset _Msh_Ho_t; then
			eval "${_Msh_Ho_f}() {
				${_Msh_H_spp}
				${_Msh_Ho_t}
				${_Msh_H_cmd} && unset -v _Msh_P${_Msh_Ho_E+ _Msh_e} || {
					_Msh_E=\$?
					if let ${_Msh_H_expr}; then
						if _Msh_harden_isSig \"\${_Msh_E}\"; then
							_Msh_P=\"killed by SIG\$REPLY: \${_Msh_P}\"
						fi
						${_Msh_Ho_E-}
						die \"${_Msh_Ho_c-${_Msh_Ho_f}: }failed with status \${_Msh_E}: \${_Msh_P}\"
					fi
					eval \"unset -v _Msh_P _Msh_E${_Msh_Ho_E+ _Msh_e}; return \${_Msh_E}\"
				}
			}${CCn}"
		else
			eval "${_Msh_Ho_f}() {
				${_Msh_H_cmd}${_Msh_Ho_E+ && unset -v _Msh_e} || {
					_Msh_E=\$?
					if let ${_Msh_H_expr}; then
						${_Msh_H_spp}
						if _Msh_harden_isSig \"\${_Msh_E}\"; then
							_Msh_P=\"killed by SIG\$REPLY: \${_Msh_P}\"
						fi
						${_Msh_Ho_E-}
						die \"${_Msh_Ho_c-${_Msh_Ho_f}: }failed with status \${_Msh_E}: \${_Msh_P}\"
					fi
					eval \"unset -v _Msh_P _Msh_E${_Msh_Ho_E+ _Msh_e}; return \${_Msh_E}\"
				}
			}${CCn}"
		fi
	fi || die "${_Msh_H_C}: fn def failed"

	eval "unset -v _Msh_Ho_c _Msh_Ho_S _Msh_Ho_X _Msh_Ho_e _Msh_Ho_f _Msh_Ho_p _Msh_Ho_t _Msh_Ho_u _Msh_Ho_E \
			_Msh_H_VA _Msh_E _Msh_H_C _Msh_H_cmd _Msh_H_expr _Msh_H_spp
		${_Msh_Ho_c+_Msh_harden_tmp}"
}

# trace: use 'harden' to trace a command with minimal hardening, i.e.: harden only against system errors
# and signals (except SIGPIPE), not command errors. Or if it's a shell function, trace it using an alias.
trace() {
	case $# in
	( 0 )	die "trace: command expected${CCn}" \
			"usage: trace [ -f <funcname> ] [ -[cSpXE] ] \\${CCn}" \
			"${CCt}[ <var=value> ... ] [ -u <var> ... ] <cmdname/path> [ <arg> ... ]" || return ;;
	esac
	if let "$# == 2" && str eq "$1" '-f'; then
		# Trace a shell function using an alias. No hardening.
		not command alias "$2" >/dev/null 2>&1 || die "trace: alias '$2' already exists" || return
		unset -v _Msh_Ho_c
		_Msh_Ho_f="$2()"
		_Msh_harden_traceInit
		# Set tracing function. Backslash command words to circumvent existing aliases.
		eval '_Msh_trace_'"$2"'() {
			_Msh_P='"$2"'
			for _Msh_A do
				\shellquote _Msh_A
				\let "${#_Msh_P} + ${#_Msh_A} >= 512" && _Msh_P="${_Msh_P} (TRUNCATED)" && \break
				_Msh_P=${_Msh_P}${_Msh_P:+" "}${_Msh_A}
			done
			'"${_Msh_Ho_t}"'
			\unset -v _Msh_A _Msh_P
			\isset -f '"$2"' || \die "trace: function not found: '"$2"'" || \return
			\'"$2"' "$@"
		}' || die "trace: fn def failed" || return
		unset -v _Msh_Ho_t _Msh_Ho_f
		command alias "$2=_Msh_trace_$2" || die "trace: alias failed"
	else
		# Minimal hardening of a regular command with tracing.
		_Msh_H_C=trace  # command name for harden() error messages
		harden -t -P -e '>125 && !=128 && !=255' "$@"
	fi
}

# -----------

# Internal function to determine if the exit status represents a signal, and
# if so, return the signal name in REPLY. If var/stack/trap is loaded, use
# 'thisshellhas --sig' to get more reliable, sanitised results from cache.
_Msh_harden_isSig() {
	let "$1 > 128" \
	&& if use -q var/stack/trap; then
		thisshellhas --sig="$1"
	else
		REPLY=$(command kill -l "$1" 2>/dev/null) \
		&& not str isint "${REPLY:-0}" \
		&& REPLY=${REPLY#[Ss][Ii][Gg]}
	fi
}

# Internal function to initialise tracing. Store commands in _Msh_Ho_t.
_Msh_harden_traceInit() {
	{ command : >&9; } 2>/dev/null || exec 9>&2
	if ! isset _Msh_Ht_R && is onterminal 9; then
		if _Msh_Ht_R=$(PATH=$DEFPATH command tput sgr0); then
			_Msh_Ht_y=${_Msh_Ht_R}$(PATH=$DEFPATH; command tput setaf 3 || command tput dim)
			_Msh_Ht_r=${_Msh_Ht_R}$(PATH=$DEFPATH; command tput setaf 1 || command tput smul)
			_Msh_Ht_b=${_Msh_Ht_R}$(PATH=$DEFPATH; command tput setaf 4; command tput bold)
		else
			_Msh_Ht_R=''
		fi
	fi 2>/dev/null
	if is onterminal 9 && ! str empty "${_Msh_Ht_R}"; then
		# highlight trace in red, yellow and blue with fallback to monochrome highlighting
		_Msh_Ho_t="\\putln \"\${_Msh_Ht_y}[\${_Msh_Ht_r}"
		isset _Msh_Ho_c && _Msh_Ho_t=${_Msh_Ho_t}${_Msh_H_C} || _Msh_Ho_t=${_Msh_Ho_t}${_Msh_Ho_f}
		_Msh_Ho_t="${_Msh_Ho_t}\${_Msh_Ht_y}]> \${_Msh_Ht_b}\${_Msh_P}\${_Msh_Ht_R}\" 1>&9"
	else	# default
		_Msh_Ho_t="\\putln \"["
		isset _Msh_Ho_c && _Msh_Ho_t=${_Msh_Ho_t}${_Msh_H_C} || _Msh_Ho_t=${_Msh_Ho_t}${_Msh_Ho_f}
		_Msh_Ho_t="${_Msh_Ho_t}]> \${_Msh_P}\" 1>&9"
	fi
}

# -----------

if thisshellhas ROFUNC; then
	readonly -f harden trace _Msh_harden_isSig _Msh_harden_traceInit
fi
