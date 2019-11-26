#! /module/for/moderni/sh
\command unalias poptrap pushtrap trap _Msh_POSIXtrap _Msh_arg2sig _Msh_arg2sig_sanitise _Msh_clearAllTrapsIfFirstInSubshell _Msh_doINTtrap _Msh_doOneStackTrap _Msh_doOneStackTrap_noSub _Msh_doTraps _Msh_printSysTrap _Msh_setSysTrap 2>/dev/null

# var/stack/trap
#
# The trap stack: pushtrap, poptrap. Set traps without overwriting others.
#
# Adds a new POSIX 'trap' command to play nice with the trap stack.
# Printing the traps with 'trap' also prints the stack traps as pushtrap
# commands. It also makes var=$(trap) work on all shells, and adds a
# bash-style 'trap -p SIGFOO SIGBAR ...' command for all shells.
#
# Adds a new DIE pseudosignal for all trap commands (including POSIX 'trap')
# whose traps get executed simultaneously if die() is called. This is
# intended to allow emergency cleanup operations. Unlike other traps, DIE
# traps are inherited by subshells.
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

use var/shellquote
use var/stack/extra/stackempty
isset -i && use var/stack/extra/clearstack

# -----------------

# Adds a command to each specified signal's trap stack, activating the
# corresponding system trap if it wasn't already active.
# Along with the command, current $IFS and $- are pushed, so they
# can be restored when that trap is executed in a subshell.
# Usage: pushtrap [ --key=<value> ] [ --nosubshell ] [ -- ] <command> <sigspec> [ <sigspec> ... ]
pushtrap() {
	unset -v _Msh_pushtrap_key _Msh_pushtrap_noSub
	while :; do
		case ${1-} in
		( -- )	shift; break ;;
		( --key=* )
			_Msh_pushtrap_key=${1#--key=} ;;
		( --nosubshell )
			_Msh_pushtrap_noSub= ;;
		( -* )	die "pushtrap: invalid option: $1" ;;
		( * )	break ;;
		esac
		shift
	done
	case $# in
	( 0|1 )	die "pushtrap: needs at least 2 non-option arguments" ;;
	esac
	case $1 in
	( *[!$WHITESPACE]* ) ;;
	( * )	die "pushtrap: empty command not supported" ;;
	esac
	case $1 in
	( *_Msh_doTraps\ * )
		die "pushtrap: cannot use internal modernish trap handler" ;;
	esac
	_Msh_pushtrapCMD=$1
	shift
	_Msh_sigs=''
	for _Msh_sig do
		_Msh_arg2sig || die "pushtrap: no such signal: ${_Msh_sig}"
		if str eq "${_Msh_sig}" DIE && isset _Msh_pushtrap_noSub; then
			die "pushtrap: --nosubshell cannot be used with DIE traps"
		fi
		_Msh_sigs=${_Msh_sigs}\ ${_Msh_sig}:${_Msh_sigv}
	done
	eval "set --${_Msh_sigs}"
	_Msh_clearAllTrapsIfFirstInSubshell
	for _Msh_sig do
		_Msh_sigv=${_Msh_sig##*:}
		_Msh_sig=${_Msh_sig%:*}
		unset -v "_Msh_trap${_Msh_sigv}_opt" "_Msh_trap${_Msh_sigv}_ifs" "_Msh_trap${_Msh_sigv}_noSub"
		eval "_Msh_trap${_Msh_sigv}=\${_Msh_pushtrapCMD}"
		if isset _Msh_pushtrap_noSub; then
			eval "_Msh_trap${_Msh_sigv}_noSub=''"
		else
			eval "_Msh_trap${_Msh_sigv}_opt=\$-"
			isset IFS && eval "_Msh_trap${_Msh_sigv}_ifs=\$IFS" || unset -v "_Msh_trap${_Msh_sigv}_ifs"
		fi
		push ${_Msh_pushtrap_key+"--key=$_Msh_pushtrap_key"} "_Msh_trap${_Msh_sigv}" \
			"_Msh_trap${_Msh_sigv}_opt" "_Msh_trap${_Msh_sigv}_ifs" "_Msh_trap${_Msh_sigv}_noSub"
		_Msh_setSysTrap "${_Msh_sig}" "${_Msh_sigv}"
		unset -v "_Msh_trap${_Msh_sigv}" "_Msh_trap${_Msh_sigv}_ifs" \
			"_Msh_trap${_Msh_sigv}_opt" "_Msh_trap${_Msh_sigv}_noSub"
	done
	unset -v _Msh_pushtrapCMD _Msh_pushtrap_key _Msh_pushtrap_noSub _Msh_sig _Msh_sigv _Msh_sigs
}

# -----------------

# Removes a trap from each signal's trap stack without executing it.
# Clear the signal's master trap if there are no more left on the stack.
# Usage: poptrap [ --key=<value> ] [ -- ] <sigspec> [ <sigspec> ... ]
# Removes *nothing* if one of the specified signals' stack is already empty,
# or if one of the values' stored keys doesn't match the specified key;
# this allows for extra validation when treating several items as a group.
# The REPLY variable will be filled with eval-ready (properly shell-quoted)
# commands to re-push each popped trap, each in the form of:
#	pushtrap -- "<command>" SIGNALNAME
# Multiple commands are separated by newline characters.
poptrap() {
	unset -v _Msh_poptrap_key _Msh_poptrap_R
	while :; do
		case ${1-} in
		( -- )	shift; break ;;
		( -R )	_Msh_poptrap_R='' ;;
		( --key=* )
			_Msh_poptrap_key=${1#--key=} ;;
		( -* )	die "poptrap: invalid option: $1" ;;
		( * )	break ;;
		esac
		shift
	done
	case $# in
	( 0 )	die "poptrap: needs at least 1 non-option argument" ;;
	esac
	_Msh_clearAllTrapsIfFirstInSubshell
	_Msh_sigs=''
	for _Msh_sig do
		_Msh_arg2sig || die "poptrap: no such signal: ${_Msh_sig}"
		if stackempty ${_Msh_poptrap_key+"--key=$_Msh_poptrap_key"} "_Msh_trap${_Msh_sigv}"; then
			unset -v _Msh_sig _Msh_sigv _Msh_sigs
			return 1
		fi
		_Msh_sigs=${_Msh_sigs}\ ${_Msh_sig}:${_Msh_sigv}
	done
	eval "set --${_Msh_sigs}"
	isset _Msh_poptrap_R && unset -v REPLY
	for _Msh_sig do
		_Msh_sigv=${_Msh_sig##*:}
		_Msh_sig=${_Msh_sig%:*}
		# (note: this assumes pop() and shellquote() don't change $REPLY)
		pop ${_Msh_poptrap_key+"--key=$_Msh_poptrap_key"} "_Msh_trap${_Msh_sigv}" \
			"_Msh_trap${_Msh_sigv}_opt" "_Msh_trap${_Msh_sigv}_ifs" "_Msh_trap${_Msh_sigv}_noSub" \
			|| die "poptrap: stack corrupted: ${_Msh_sig}"
		if isset _Msh_poptrap_R; then
			shellquote -f "_Msh_trap${_Msh_sigv}"
			eval "REPLY=\"\${REPLY+\$REPLY\$CCn}pushtrap" \
				"\${_Msh_poptrap_key+--key=\$_Msh_poptrap_key" \
				"}\${_Msh_trap${_Msh_sigv}_noSub+--nosubshell" \
				"}-- \${_Msh_trap${_Msh_sigv}} ${_Msh_sig}\""
		fi
		unset -v "_Msh_trap${_Msh_sigv}" "_Msh_trap${_Msh_sigv}_opt" \
			"_Msh_trap${_Msh_sigv}_ifs" "_Msh_trap${_Msh_sigv}_noSub"
		_Msh_setSysTrap "${_Msh_sig}" "${_Msh_sigv}"
	done
	unset -v _Msh_sig _Msh_sigv _Msh_sigs _Msh_poptrap_key _Msh_poptrap_R
}

# -----------------

# Do the traps for a signal. Start from the top of the stack, but don't pop
# the commands, as they may be trapped repeatedly. Also handle the traps for
# the POSIX 'trap' command defined below.
_Msh_doTraps() {
	# Save current exit status in $3.
	set -- "$1" "$2" "$?"
	# Execute the commands on the trap stack, last to first, if any.
	if ! stackempty --force "_Msh_trap${2}"; then
		_Msh_doTraps_i=$((_Msh__V_Msh_trap${2}__SP))
		while let '(_Msh_doTraps_i-=1) >= 0'; do
			if isset "_Msh__V_Msh_trap${2}_noSub__S${_Msh_doTraps_i}"; then
				_Msh_doOneStackTrap_noSub "${2}" "${_Msh_doTraps_i}" "${3}"
			else
				# Execute stack traps in a subshell by default, so 'exit' cannot stop the trap stack and
				# traps from different modules can't interfere with each other (or the main shell).
				(_Msh_doOneStackTrap "${2}" "${_Msh_doTraps_i}" "${3}")
			fi
		done
		unset -v _Msh_doTraps_i
	fi
	# Remember any emulated POSIX trap action to be executed immediately after this function.
	if isset "_Msh_POSIXtrap${2}"; then
		eval "_Msh_PT=\${_Msh_POSIXtrap${2}}"
	else
		unset -v _Msh_PT
	fi
	# On interactive shells, SIGINT is used for cleanup after die(), so clear
	# out the SIGINT stack traps to make sure they are executed only once.
	if isset -i && str eq "$1" INT && ! insubshell; then
		isset _Msh_PT && _Msh_doINTtrap "$2" "$3"
		unset -v "_Msh_POSIXtrap${2}" _Msh_PT
		clearstack --force --trap=INT
		command trap - INT
		# bash < 5.0 has a bug that causes an interactive shell to exit upon resending SIGINT.
		if ! str match "${BASH_VERSION-}" '[1234].*'; then
			command kill -s INT "$$"
		fi
		return 128
	fi
	# If the signal was ignored contrary to expectations, unignore and resend it.
	# Ref.: http://pubs.opengroup.org/onlinepubs/9699919799/basedefs/signal.h.html
	if	! isset "_Msh_POSIXtrap${2}" &&		# ...if there is no emulated POSIX trap...
		{ ! isset -i || insubshell; } &&	# ...and the shell is not interactive (or is a subshell of interactive)...
		case $1 in				# ...and signal is not pseudo, and not one that does not kill the shell...
		( "$2" | ERR | ZERR | CHLD | CONT | STOP | TSTP | TTIN | TTOU | URG )
			! : ;;
		esac
	then
		# If in subshell, get our subshell PID.
		push REPLY
		insubshell -p && _Msh_sPID=$REPLY || unset -v _Msh_sPID
		pop REPLY
		# bash and ksh will trigger the EXIT trap on sending any untrapped signal, which is
		# inconsistent with other shells. Remedy this for stack traps in scripts only.
		if ! isset -i && ! isset _Msh_sPID; then
			command trap - 0  # BUG_TRAPEXIT compat
		fi
		# Unignore (by unsetting the trap) and resend the signal, possibly killing the shell.
		command trap - "$1"
		case $1 in
		( *[!0123456789]* )
			command kill -s "$1" "${_Msh_sPID:-$$}" 2>/dev/null ;;	# signal name
		( * )	command kill "-$1" "${_Msh_sPID:-$$}" 2>/dev/null ;;	# signal with no name (number only)
		esac || {
			# If 'kill' failed, it must have been a pseudosignal. Restore.
			_Msh_setSysTrap "$1" "$2"
			if ! isset -i && ! isset _Msh_sPID; then
				_Msh_setSysTrap EXIT EXIT
			fi
			unset -v _Msh_sPID
		}
		# (Note: some shells (zsh, older bash) will keep running until the end of
		# the trap routine and then act on the suicide. But since the 'kill' is the
		# last command executed here if a signal is resent, this doesn't matter.)
	fi
	return "$3"  # pass exit status to 'eval' for POSIX trap; see _Msh_setSysTrap()
}
# Wrapper function for INT trap on interactive shells.
_Msh_doINTtrap() {
	eval "shift; setstatus $2; eval \" \${_Msh_POSIXtrap$1}\""
	#				  ^ QRK_EVALNOOPT compat
}
# Same for a stack trap. Always run this in a subshell.
_Msh_fork=''
_Msh_reallyunsetIFS='unset -v IFS'
thisshellhas NONFORKSUBSH && _Msh_fork='command ulimit -t unlimited 2>/dev/null'
{ thisshellhas QRK_LOCALUNS || thisshellhas QRK_LOCALUNS2; } && _Msh_reallyunsetIFS='while isset IFS; do unset -v IFS; done'
eval '_Msh_doOneStackTrap() {
	'"${_Msh_fork}"'
	# restore '\''use safe'\''-related shell options stored by pushtrap
	eval "_Msh_doTraps_o=\${_Msh__V_Msh_trap${1}_opt__S${2}}"
	case ${-},${_Msh_doTraps_o} in (*f*,*f*) ;; (*f*,*) set +f;; (*,*f*) set -f;; esac
	case ${-},${_Msh_doTraps_o} in (*u*,*u*) ;; (*u*,*) set +u;; (*,*u*) set -u;; esac
	case ${-},${_Msh_doTraps_o} in (*C*,*C*) ;; (*C*,*) set +C;; (*,*C*) set -C;; esac
	# restore IFS stored by pushtrap
	if isset "_Msh__V_Msh_trap${1}_ifs__S${2}"; then
		eval "IFS=\${_Msh__V_Msh_trap${1}_ifs__S${2}}"
	else
		'"${_Msh_reallyunsetIFS}"'
	fi
	# execute trap
	eval "shift 3; setstatus $3; eval \" \${_Msh__V_Msh_trap${1}__S${2}}\"" && :
}'
unset -v _Msh_fork _Msh_reallyunsetIFS
# Same for a --nosubshell stack trap.
_Msh_doOneStackTrap_noSub() {
	eval "shift 3; setstatus $3; eval \" \${_Msh__V_Msh_trap${1}__S${2}}\""
}

# -----------------

# Alias the builtin 'trap' command to a replacement to avoid overwriting other
# traps on the same signal. (Overriding 'trap' with a function doesn't work
# on every shell; an alias is more reliable.) This command should conform to:
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#trap
alias trap='_Msh_POSIXtrap'
_Msh_POSIXtrap() {
	if let "$# == 0" || str eq "${#},$1" '1,--' || str eq "$1" '-p' || str eq "$1" '--print'; then
		# Print the traps, both legacy and stack.
		_Msh_pT_E=0
		unset -v _Msh_pT_s2p  # s2p = signals to print (skip others)
		let "$#" && shift && while let "$#"; do
			if _Msh_arg2sig "$1"; then
				_Msh_pT_s2p="${_Msh_pT_s2p-} ${_Msh_sig}"
			else
				putln "trap (print): no such signal: ${_Msh_sig}" >&2
				_Msh_pT_E=1
			fi
			shift
		done
		# We need to get the shell to parse the 'trap --' commands generated by 'trap'.
		# This is done by temporarily aliasing 'trap' to _Msh_printSysTrap().
		unset -v _Msh_pT_done
		if thisshellhas TRAPPRSUBSH \
		&& ! { push REPLY; insubshell -u && ! str eq "$REPLY" "${_Msh_trap_subshID-}"; pop --keepstatus REPLY; }; then
			# If we didn't just enter a new subshell, we can obtain the traps using a command substitution.
			_Msh_trap=$(command trap) || die "trap: system error: builtin failed"
			alias trap='_Msh_printSysTrap'
			eval "${_Msh_trap}" || die "trap: internal error"
			alias trap='_Msh_POSIXtrap'
			unset -v _Msh_trap
		else
			# We must use a temporary file as a dot script. Be atomic.
			_Msh_trapd=$(unset -v _Msh_D _Msh_i
				umask 077
				until	_Msh_D=/tmp/_Msh_trapd.$$.${_Msh_i=${RANDOM:-0}}
					PATH=$DEFPATH command mkdir "${_Msh_D}" 2>/dev/null	# 'mkdir' is atomic
				do	let "$? > 125" && _Msh_doExit 1 "trap: system error: 'mkdir' failed"
					is -L dir /tmp && can write /tmp \
						|| _Msh_doExit 1 "trap: system error: /tmp directory not writable"
					_Msh_i=$(( ${RANDOM:-_Msh_i + 1} ))
				done
				: > "${_Msh_D}/systraps" || exit 1
				put "${_Msh_D}"
			) || die "trap: internal error: can't create temporary directory"
			# Write output of 'trap' builtin to temp file, checking command success and write success separately.
			{	command trap || die "trap: system error: builtin failed"
			} >| "${_Msh_trapd}/systraps" || die "trap: system error: can't write to temp file"
			# Parse.
			alias trap='_Msh_printSysTrap'
			command . "${_Msh_trapd}/systraps" || die "trap: internal error"
			alias trap='_Msh_POSIXtrap'
			# Cleanup.
			case $- in
			( *i* | *m* )
				PATH=$DEFPATH command rm -rf "${_Msh_trapd}" ;;
			( * )	PATH=$DEFPATH command rm -rf "${_Msh_trapd}" & ;;
			esac
			unset -v _Msh_trapd
		fi
		push REPLY
		if ! thisshellhas TRAPPRSUBSH && insubshell -u && ! str eq "$REPLY" "${_Msh_trap_subshID-}"; then
			# Detect traps we missed. This makes printing traps work in a subshell, e.g. v=$(trap)
			_Msh_signum=-1
			while let "(_Msh_signum+=1)<128"; do
				_Msh_arg2sig "${_Msh_signum}" || continue
				case "|${_Msh_pT_done-}|" in (*"|${_Msh_sig}|"*) continue;; esac
				_Msh_printSysTrap -- "_Msh_doTraps ${_Msh_sig} ${_Msh_sigv}" "${_Msh_sig}"
			done
		fi
		pop REPLY
		# Print the ERR trap. On some shells, it is not inherited by functions.
		if _Msh_arg2sig ERR \
		&& { isset "_Msh_POSIXtrap${_Msh_sigv}" || ! stackempty --force "_Msh_trap${_Msh_sigv}"; } \
		&& ! str in "|${_Msh_pT_done-}|" "|${_Msh_sig}|"; then
			_Msh_printSysTrap -- "_Msh_doTraps ERR ${_Msh_sigv}" ERR
		fi
		# Print the DIE trap.
		if isset _Msh_POSIXtrapDIE || ! stackempty --force _Msh_trapDIE; then
			_Msh_printSysTrap -- '_Msh_doTraps DIE DIE' DIE
		fi
		eval "unset -v _Msh_sig _Msh_sigv _Msh_signum _Msh_pT_done _Msh_pT_s2p _Msh_pT_E
		      return ${_Msh_pT_E}"
	elif let "$# == 1" && { str match "$1" '-[!-]*' || str match "$1" '--?*'; }; then
		# allow system-specific things such as "trap -l" (bash) or "trap --help" (ksh93, yash)
		command trap "$@"
		return
	fi

	_Msh_clearAllTrapsIfFirstInSubshell

	case $1 in
	( -- )	shift ;;
	esac

	case ${1-} in
	( '' | *[!0123456789]* ) ;;
	( * )	# First operand is unsigned integer: reset signals.
		set -- - "$@" ;;
	esac

	_Msh_trap_E=0
	if let "$# == 1" || str eq "$1" '-'; then
		# Emulation of system command to unset a trap.
		if str eq "$1" '-'; then
			shift
			let "$#" || die 'trap (unset): at least one signal expected'
		fi
		for _Msh_sig do
			if _Msh_arg2sig; then
				unset -v "_Msh_POSIXtrap${_Msh_sigv}"
				_Msh_setSysTrap "${_Msh_sig}" "${_Msh_sigv}"
			else
				putln "trap (unset): no such signal: ${_Msh_sig}" >&2
				_Msh_trap_E=1
			fi
		done
	else
		# Emulation of system command to set a trap.
		let "$# > 1" || die "trap (set): at least one signal expected"
		not str in "$1" '_Msh_doTraps ' || die "trap (set): cannot use internal modernish trap handler"
		_Msh_trap_CMD=$1
		shift
		for _Msh_sig do
			if _Msh_arg2sig; then
				eval "_Msh_POSIXtrap${_Msh_sigv}=\${_Msh_trap_CMD}"
				_Msh_setSysTrap "${_Msh_sig}" "${_Msh_sigv}"
			else
				putln "trap (set): no such signal: ${_Msh_sig}" >&2
				_Msh_trap_E=1
			fi
		done
	fi
	eval "unset -v _Msh_sig _Msh_sigv _Msh_trap_CMD _Msh_trap_E; return ${_Msh_trap_E}"
}

# -----------------

# Internal function to interpret the output of the system 'trap' command with no operands.
# We're parsing 'trap' arguments as specified here:
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_28_03
_Msh_printSysTrap() {
	case ${#},${1-} in
	(2,--)	if thisshellhas BUG_TRAPEMPT "--sig=$2"; then
			# pdksh/mksh fails to quote empty trap actions.
			set -- "$1" "" "$2"
		elif str match "$2" "_Msh_doTraps EXIT EXIT[ ;${CCn}]*"; then
			# Workaround for intermittent bug on zsh 5.0.7 and 5.0.8. TODO: remove when support stops.
			# With this bug, the 'trap' builtin sometimes does not print the EXIT pseudosignal name.
			set -- "$1" "$2" "EXIT"
		fi ;;
	esac
	case ${#},${1-} in
	( 3,-- ) ;;
	( * )	die "trap: internal error: unexpected output of system 'trap' command" ;;
	esac
	case "${_Msh_pT_s2p+s}, ${_Msh_pT_s2p-} " in
	( ,* | s,*" $3 "* ) ;;
	( * )	return ;;  # skip if s2p is set and sig not in it
	esac
	case $2 in
	( "_Msh_doTraps "* )
		# this trap was set by a modernish function
		_Msh_sig=${2#_Msh_doTraps }
		_Msh_sigv=${_Msh_sig#* }
		_Msh_sigv=${_Msh_sigv%%[ ;${CCn}]*}  # zsh stores traps as wordcode, changing ';' to newline
		_Msh_sig=${_Msh_sig%% *}
		if isset "_Msh__V_Msh_trap${_Msh_sigv}__SP"; then
			# print the traps set by 'pushtrap'
			_Msh_pT_i=-1
			while let "(_Msh_pT_i+=1) < _Msh__V_Msh_trap${_Msh_sigv}__SP"; do
				eval "_Msh_pT_cmd=\${_Msh__V_Msh_trap${_Msh_sigv}__S${_Msh_pT_i}}"
				shellquote -f _Msh_pT_cmd
				if isset "_Msh__V_Msh_trap${_Msh_sigv}__K${_Msh_pT_i}"; then
					eval "_Msh_pT_key=\${_Msh__V_Msh_trap${_Msh_sigv}__K${_Msh_pT_i}}"
					shellquote _Msh_pT_key
				else
					unset -v _Msh_pT_key
				fi
				if isset "_Msh__V_Msh_trap${_Msh_sigv}_noSub__S${_Msh_pT_i}"; then
					_Msh_pT_noSub=
				else
					unset -v _Msh_pT_noSub
				fi
				put 'pushtrap' \
					${_Msh_pT_key+"--key=$_Msh_pT_key"} \
					${_Msh_pT_noSub+"--nosubshell"} \
					"-- ${_Msh_pT_cmd} ${_Msh_sig}${CCn}"
			done
			unset -v _Msh_pT_i
		fi
		if isset "_Msh_POSIXtrap${_Msh_sigv}"; then
			# print the trap set by the emulated POSIX 'trap' command
			eval "_Msh_pT_cmd=\${_Msh_POSIXtrap${_Msh_sigv}}"
			shellquote -f _Msh_pT_cmd
			putln "trap -- ${_Msh_pT_cmd} ${_Msh_sig}"
		fi ;;
	( '' )	# this signal is being ignored
		_Msh_arg2sig "$3" || die "trap: internal error: invalid trap name: ${_Msh_sig}"
		eval "_Msh_POSIXtrap${_Msh_sigv}="  # bring it into the modernish fold
		putln "trap -- '' ${_Msh_sig}" ;;
	( * )	# this trap was set directly by the system command
		_Msh_arg2sig "$3" || die "trap: internal error: invalid trap name: ${_Msh_sig}"
		# Bring it into the modernish fold so 'pushtrap' won't overwrite it.
		eval "_Msh_POSIXtrap${_Msh_sigv}=\$2"
		_Msh_setSysTrap "${_Msh_sig}" "${_Msh_sigv}"
		shellquote -f _Msh_pT_cmd="$2"
		putln "trap -- ${_Msh_pT_cmd} ${_Msh_sig}" ;;
	esac
	_Msh_pT_done=${_Msh_pT_done-}${_Msh_pT_done:+\|}${_Msh_sig}
	unset -v _Msh_pT_cmd _Msh_pT_key _Msh_pT_noSub _Msh_sig _Msh_sigv
}

# -----------------

# Internal function to (un)set a builtin trap to be handled by modernish.
# Usage: _Msh_setSysTrap <sigName> <varNameComponent>
_Msh_setSysTrap() {
	case $1 in
	(DIE)	return ;;
	esac
	if ! isset "_Msh_POSIXtrap$2" && stackempty --force "_Msh_trap$2"; then
		_Msh_sST_A='-'	# unset builtin trap
	elif eval "str empty \"\${_Msh_POSIXtrap$2-U}\"" && stackempty --force "_Msh_trap$2"; then
		_Msh_sST_A=''	# ignore signal
	else
		case $1 in
		(ERR | ZERR)
			# avoid possible infinite recursion with '&& :'
			_Msh_sST_A="_Msh_doTraps $1 $2 && :; eval \"\${_Msh_PT+unset _Msh_PT;\${_Msh_PT}}\" && :"
			if isset BASH_VERSION; then
				# on bash, we cannot unset the native ERR trap from a function, so do it directly
				_Msh_sST_A="${_Msh_sST_A}; case \${_Msh_POSIXtrapERR+s}\${_Msh__V_Msh_trapERR__SP+s} in "
				_Msh_sST_A="${_Msh_sST_A}('') command trap - ERR;; esac"
			fi ;;
		( * )	_Msh_sST_A="_Msh_doTraps $1 $2; eval \"\${_Msh_PT+unset _Msh_PT;\${_Msh_PT}}\"" ;;
		esac
		case $1 in
		( RETURN )
			thisshellhas BUG_TRAPRETIR && set +o functrace ;;
		esac
	fi
	case $1 in
	(EXIT)	command trap "${_Msh_sST_A}" 0 ;; # BUG_TRAPEXIT compat
	( * )	command trap "${_Msh_sST_A}" "$1" ;;
	esac || die "internal error: the 'trap' builtin failed"
	unset -v _Msh_sST_A
}

# -----------------

# Internal function for commands that change the trap stack (_Msh_POSIXtrap(), pushtrap(),
# et al). If we're in a subshell, keep track of whether this is the first such command
# executed in this subshell. If it is, then the shell has just reset all native traps, so
# in order to avoid inconsistencies we must clear all modernish traps as well.
# This function is also run once at init to disallow inheriting traps from the environment.
unset -v _Msh_trap_subshID
if thisshellhas BUG_SETOUTVAR && (set +o posix && command typeset -g) >/dev/null 2>&1; then
	# yash <= 2.46: We can't use 'set' to print all variables for searching, so use 'typeset -g' instead.
	_Msh_set='(command set +o posix; command typeset -g | exec sed "s/^typeset -[a-z][a-z]* //; s/^typeset //")'
else
	_Msh_set='set'
fi
eval '_Msh_clearAllTrapsIfFirstInSubshell() {
	push REPLY
	insubshell -u
	if str ne "$REPLY" "${_Msh_trap_subshID-}"; then
		# Keep track.
		_Msh_trap_subshID=$REPLY
		pop REPLY
		# Find and unset all the internal trap stack variables, except for DIE traps which survive in subshells.
		# The "sed" incantation below could yield false positives due to newlines in variable values, but only
		# false positives that are valid identifiers in the variable namespaces we are trying to unset anyway.
		_Msh_trap=$(
			export PATH=$DEFPATH LC_ALL=C
			unset -f sed  # QRK_EXECFNBI compat
			'"${_Msh_set}"' | exec sed -n "\
				/^_Msh_POSIXtrapDIE=/ d
				/^_Msh__V_Msh_trapDIE_[a-zA-Z0-9_]*=/ d
				/^_Msh_POSIXtrap[A-Z0-9_][A-Z0-9_]*=/ s/=.*//p
				/^_Msh__V_Msh_trap[A-Z0-9_][a-zA-Z0-9_]*=/ s/=.*//p"
		) || die "internal error: clear all traps: sed failed"
		push IFS
		IFS=$CCn
		command unset -v ${_Msh_trap} _Msh_trap
		pop --keepstatus IFS || die "internal error: clear all traps: unset failed"
	else
		pop REPLY
	fi
}'
unset -v _Msh_set

# -----------------------
# --- Signal handling ---

# Convert an argument in either ${_Msh_sig} or the first argument to a signal name minus the SIG
# prefix, check it for validity, sanitise it, and leave the result in ${_Msh_sig}. The
# corresponding variable name component is left in ${_Msh_sigv}.
# Returns unsuccessfully if the argument does not correspond to a valid signal.
# Internal function; not for use by programs. Subject to change without notice.
_Msh_psigCache=
_Msh_arg2sig() {
	unset -v _Msh_sigv
	case ${1:+n} in
	( n )	_Msh_sig=$1 ;;
	esac
	case ${_Msh_sig} in
	( 0 )	_Msh_sig=EXIT; _Msh_sigv=EXIT ;;
	( *[!0123456789]* )
		# Signal name: sanitise and validate
		_Msh_arg2sig_sanitise || return 1
		case ${_Msh_sig} in
		( DIE )	if isset -i; then	# on an interactive shell,
				_Msh_sig=INT	# ... alias DIE to INT.
			else
				_Msh_sigv=DIE
				return
			fi ;;
		( EXIT )_Msh_sigv=EXIT
			return ;;
		( ERR )	if thisshellhas TRAPZERR; then
				_Msh_sigv=ZERR
				return
			fi ;;
		esac
		# Check the 'kill -l' cache to see if it's known
		case ${_Msh_sigCache} in
		( *\|${_Msh_sig}${CCn}* )
			# use signal number as varname component
			_Msh_sigv=${_Msh_sigCache%\|${_Msh_sig}${CCn}*}
			_Msh_sigv=${_Msh_sigv##*${CCn}} ;;
		( * )	# check for shell-specific numberless pseudosignal
			case ${_Msh_sig} in
			( *[!${ASCIIALNUM}_]* )
				return 1 ;;  # must be valid varname component
			esac
			# testing for a pseudosig requires forking a subshell, so cache results
			case "|${_Msh_psigCache}|" in
			( *"|${_Msh_sig}|"* )
				_Msh_sigv=${_Msh_sig} ;;
			( *"|!${_Msh_sig}|"* )
				return 1 ;;
			( * )	if (command trap - "${_Msh_sig}") 2>/dev/null; then
					_Msh_sigv=${_Msh_sig}
					_Msh_psigCache=${_Msh_psigCache}${_Msh_psigCache:+\|}${_Msh_sig}
				else
					_Msh_psigCache=${_Msh_psigCache}${_Msh_psigCache:+\|}!${_Msh_sig}
					return 1
				fi ;;
			esac ;;
		esac ;;
	( * )	# Signal number: retrieve a 'kill -l' name from the cache
		case ${_Msh_sigCache} in
		( *${CCn}$((_Msh_sig % 128))\|[!${CCn}]* )
			_Msh_sigv=$((_Msh_sig % 128))
			_Msh_sig=${_Msh_sigCache#*${CCn}${_Msh_sigv}\|}
			_Msh_sig=${_Msh_sig%%${CCn}*} ;;
		( * )	return 1 ;;
		esac ;;
	esac
}
# Sanitise/canonicalise the signal name in _Msh_sig. Return unsuccessfully if it's not syntactically valid.
_Msh_arg2sig_sanitise() {
	case ${_Msh_sig} in
	( '' | *[!"$SHELLSAFECHARS"]* )
		return 1 ;;
	( [Ss][Ii][Gg][Nn][Aa][Ll][123456789]* )
		# DragonflyBSD's SignalNN names are unusable, though the signals exist; change back to number
		_Msh_sig=${_Msh_sig#[Ss][Ii][Gg][Nn][Aa][Ll]} ;;
	( *[abcdefghijklmnopqrstuvwxyz]* )
		_Msh_sig=$(unset -f tr	# QRK_EXECFNBI compat
			putln "${_Msh_sig}" | PATH=$DEFPATH LC_ALL=C exec tr a-z A-Z) ;;
	( *[!0123456789]* )
		;;
	( * )	# It's a signal number, not a name
		return 1 ;;
	esac
	_Msh_sig=${_Msh_sig#SIG}
}

# -------------------
# --- Module init ---

# Since 'kill -l' is not reliably portable, initialise a cache of sanitised 'kill -l' results.
_Msh_sigCache=
push IFS -f _Msh_sig _Msh_num
IFS=\|; set -f  # split the cmd. subst. below on '|' without globbing
for _Msh_sig in $(
	: 1>&1	# BUG_CSUBSTDO workaround
	_Msh_i=0 PATH=$DEFPATH
	while let "(_Msh_i+=1)<128"; do
		command kill -l "${_Msh_i}" && put "${_Msh_i}|"
	done 2>/dev/null)
do
	_Msh_num=${_Msh_sig##*$CCn}
	_Msh_sig=${_Msh_sig%$CCn*}
	_Msh_arg2sig_sanitise || continue  # Sanitise even 'kill -l' output; it's not always reliable
	_Msh_sigCache=${_Msh_sigCache:-${CCn}}${_Msh_num}\|${_Msh_sig}${CCn}
done
pop IFS -f _Msh_sig _Msh_num
readonly _Msh_sigCache

# Disallow inheriting trap variables from environment.
_Msh_clearAllTrapsIfFirstInSubshell

# Bring any pre-set native traps into the modernish fold.
eval 'trap >/dev/null'

# -----------------

if thisshellhas ROFUNC; then
	readonly -f poptrap pushtrap \
		_Msh_POSIXtrap _Msh_clearAllTrapsIfFirstInSubshell \
		_Msh_doINTtrap _Msh_doOneStackTrap _Msh_doOneStackTrap_noSub _Msh_doTraps \
		_Msh_printSysTrap _Msh_setSysTrap
fi
