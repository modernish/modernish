#! /module/for/moderni/sh
\command unalias _loopgen_find 2>/dev/null

# modernish loop/find
#
# This powerful iteration generator turns the POSIX 'find' command into a shell
# loop, fully integrating both 'find' and 'xargs' functionality into the shell.
# The complications of using 'find' and 'xargs' as external commands are gone.
# It "just works", even when processing file names containing spaces, linefeeds
# and other strange characters. When combining 'LOOP find' with modernish 'use
# safe' mode (eliminating split & glob pitfalls), robust file processing using
# POSIX 'find' is no longer higher shell voodoo; it is the default.
#
# Usage:
#
# LOOP find [ <options> ] <varname> in <path> ... [ <find-expression> ]; DO
#	<commands>
# DONE
#
# LOOP find [ <options> ] --xargs in <path> ... [ <find-expression> ]; DO
#	<commands>
# DONE
#
# The <find-expression> is passed on to your local 'find' command. Output
# primaries (-print*) are not supported; just use shell commands to print.
# Instead, one new primary is added: -iterate, which causes the shell to
# iterate through the loop based on the results of the <find-expression>.
# As with -print on regular 'find', -iterate is appended by default if not
# present, but it can be explicitly used any number of times in the
# expression just like -print.
#
# Using '--xargs' instead of a variable name supplies simple xargs-like
# functionality. Instead of one iteration per found item, as many items as
# possible per iteration are stored into the positional parameters (PPs), so
# the shell can access them in the usual way using "$@" and such. Note that the
# --xargs option therefore overwrites the current PPs.
#    On shells with KSHARRAY, another form '--xargs=VARNAME' is supported,
# which stores the results in the array named VARNAME instead.
#    Modernish clears the PPs or the array upon completion of the loop, but if
# the loop exits before completion (e.g. 'break'), the last chunk of positional
# parameters or array elements will survive the loop.
#
# '--glob' and '--fglob' options are available as in 'LOOP for'.
# Using these options with pathname expansion globally active is a fatal error.
# They apply pathname expansion to the <path> arguments only, and NOT to any
# patterns in the <find-expression>. Their behaviour is as follows:
#   --glob: Any nonexistent path names ouput warnings to standard error and set
#	    the loop's exit status to 103 (ASCII 'g'). At least one of the path
#	    names must match an existing path; if not, the program dies.
#  --fglob: All path names must match. Any nonexistent paths kill the program.
#
# Portable scripts should otherwise only use options and primaries supported
# by POSIX, so ignore your local 'man find' page and consult this instead:
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/find.html
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

# -----

# Initialisation

use var/loop

# ... Find a POSIX-compliant 'find', one with '-path' and '{} +'.
#     http://pubs.opengroup.org/onlinepubs/9699919799/utilities/find.html
#     This *should* be the default 'find' on all systems in 2019, but:
#	- Solaris <= 11.3 'find' doesn't have -path
#	- Busybox <= 1.30.0 'find' doesn't combine '{} +' with parentheses

push IFS -f; IFS=; set -f
unset -v _loop_find_myUtil
for _loop_util in find bsdfind gfind gnufind; do
	_loop_dirdone=:
	IFS=':'; for _loop_dir in $DEFPATH $PATH; do IFS=
		str in ${_loop_dirdone} :${_loop_dir}: && continue
		if can exec ${_loop_dir}/${_loop_util} \
		&& _loop_err=$(PATH=$DEFPATH POSIXLY_CORRECT=y exec 2>&1 ${_loop_dir}/${_loop_util} \
			/dev/null \( -exec printf '%s\n' {} + \) -o \( -path /dev/null -depth -xdev \) -print) \
		&& str id ${_loop_err} /dev/null
		then
			_loop_find_myUtil=${_loop_dir}/${_loop_util}
			break 2
		fi
		_loop_dirdone=${_loop_dirdone}${_loop_dir}:
	done
done
unset -v _loop_dirdone _loop_dir _loop_util _loop_err
pop IFS -f
if not isset _loop_find_myUtil; then
	putln "loop/find: cannot find a POSIX-compliant 'find' utility"
	return 1
fi
shellquote _loop_find_myUtil	# because it will be eval'ed
readonly _loop_find_myUtil

# ... Make sure the KSHARRAY feature test result is cached for _loopgen_find().

thisshellhas KSHARRAY

# -----

# The loop parser and iteration generator function.
#
# REMINDER: loop generators are always launched in 'safe mode', with no global split or glob. Settings
# are "IFS=''; set -fCu". So, variable expansions here usually don't need to be quoted.
#    The same does *NOT* apply to commands output >&8 by loop generators for evaluation in the main shell!
# Any program may use these, so they need to work for any value of these settings. Quote everything.
#
# NOTE: --glob/--fglob options (as in 'LOOP for') subject the pathnames
# to pathname expansion, but *not* any patterns in the primaries.

_loopgen_find() {
	PATH=$DEFPATH
	shift		# abandon loop type
	_loop_status=0  # default exit status

	# 1. Remember arbitrary single-argument 'find' options, and our own --xargs and --*glob.
	#    BUG: options with separate option-arguments cannot be supported as we don't have knowledge of the local
	#    implementation's options. For instance, using the BSD find '-f PATH' option will cause strange behaviour.
	#    Note: the POSIX standard specifies no options with arguments.
	_loop_find="POSIXLY_CORRECT=y ${_loop_find_myUtil}"
	unset -v _loop_xargs _loop_V _loop_glob
	while str left ${1-} '-'; do
		case $1 in
		( --xargs )
			export _loop_xargs= ;;
		( --xargs=* )
			thisshellhas KSHARRAY || _loop_die "find: --xargs=<array> requires a shell with KSHARRAY"
			export _loop_xargs=${1#--xargs=}
			_loop_checkvarname find ${_loop_xargs} ;;
		( --glob )
			_loop_glob= ;;
		( --fglob )
			_loop_glob=f ;;
		( -- )	_loop_find="${_loop_find} --"
			shift; break ;;
		( * )	_loop_opt=$1
			shellquote _loop_opt  # because it will be eval'ed
			_loop_find="${_loop_find} ${_loop_opt}" ;;
		esac
		shift
	done
	if isset _loop_glob; then
		put >&8 "isset -f || die 'LOOP find: --${_loop_glob}glob cannot be used with global glob enabled'; "
	fi

	# 2. Parse variable name and 'in'.
	let $# || _loop_die "find: variable name expected"
	if not isset _loop_xargs; then
		_loop_checkvarname find $1
		export _loop_V=$1
		shift
	fi
	#    TODO? Make 'in <paths>' optional and default to 'in .'. This would require
	#          ensuring that no further pathname arguments exist if 'in' is skipped.
	str id $1 'in' || _loop_die "find: 'in' expected"
	shift

	# 3. Parse path names.
	#    Apply glob or fglob if requested.
	unset -v _loop_paths
	while let $# && not str left $1 '-' && not str id $1 '(' && not str id $1 '!'; do
		not isset _loop_paths && _loop_paths=
		isset _loop_glob && set +f
		for _loop_A in $1; do set -f
			if not is present ${_loop_A}; then
				case ${_loop_glob-NO} in
				( '' )	shellquote -f _loop_A
					putln "LOOP find: warning: no such path: ${_loop_A}" >&2
					_loop_status=103
					continue ;;
				( f )	shellquote -f _loop_A
					_loop_die "find: no such path: ${_loop_A}" ;;
				esac
			fi
			case ${_loop_glob+G},${_loop_A} in
			( G,-* | G,\( | G,\! )
				# Avoid accidental parsing as primary.
				_loop_A=./${_loop_A} ;;  
			esac
			shellquote _loop_A
			_loop_paths=${_loop_paths}${_loop_paths:+ }${_loop_A}
		done
		shift
	done
	if not isset _loop_paths; then
		_loop_die "find: at least one path required after 'in'"
	fi
	#    If no patterns match, we could exit here. But we want to make sure to
	#    die() on syntax error first, so the exit is delayed until step 6 below.

	# 4. Parse and validate primaries.
	#    For robust 'find' syntax parsing, any user-supplied 'find' expression is wrapped in
	#    parenthesis arguments. Any output generated by -print* or -exec* would be eval'ed by the
	#    shell and wreak havoc, so they are blocked. Instead, we implement our own -iterate primary.
	_loop_exec='-exec $MSH_SHELL $MSH_PREFIX/bin/modernish $MSH_PREFIX/libexec/modernish/var/loop/find-aux.sh {} +'
	unset -v _loop_haveExec
	_loop_prims=
	while let $#; do
		str empty ${_loop_prims} && _loop_prims='\('
		case $1 in
		( -iterate )
			# Replace any -iterate by our -exec
			_loop_prims=${_loop_prims}${_loop_prims:+ }${_loop_exec}
			_loop_haveExec=y ;;
		( -ok | -okdir )
			_loop_die "find: primary '$1' not supported" ;;
		( * )	_loop_A=$1
			shellquote _loop_A
			_loop_prims="${_loop_prims} ${_loop_A}" ;;
		esac
		shift
	done
	if not str empty ${_loop_prims}; then
		_loop_prims="${_loop_prims} \\)"
		# The 'find' utility exits with the same status 1 on *any* issue, leaving us with no way
		# to distinguish between a minor warning and something fatal like a syntax error. This is
		# unacceptable in the modernish design philosophy; we *must* die on bad syntax. Since 'find'
		# utilities differ in what they accept, we must invoke a separate 'find' to validate them.
		# The expression below makes sure anything after '-prune' is only parsed and never executed.
		eval "${_loop_find} /dev/null -prune -o ${_loop_prims} -print" || _loop_die "find: invalid arguments"
	fi
	if not isset _loop_haveExec; then
		_loop_prims="${_loop_prims} ${_loop_exec}"
	fi

	# 5. If we don't have path names, exit now.
	if str empty ${_loop_paths}; then
		putln "! _loop_E=${_loop_status}" >&8
		exit
	fi

	# 6. Run the 'find' utility.
	#    Redirect standard output to standard error so '-print' and friends can be used for debugging.
	#    Pass on FD 8 with 8>&8 (ksh93 needs this) so the -exec'ed find-aux.sh can write iteration commands.
	if isset _loop_DEBUG; then
		( eval "set -- ${_loop_find} ${_loop_paths} ${_loop_prims}"
		  shellquoteparams
		  put "[DEBUG] $@ 1>&2 8>&8$CCn" >&2 )
	fi
	eval "${_loop_find} ${_loop_paths} ${_loop_prims} 1>&2 8>&8"
	_loop_status=$(( _loop_status > $? ? _loop_status : $? ))
	if let '_loop_status > 125'; then
		# Use cold hard 'die' and not '_loop_die': don't rely on our pipe for system errors
		case ${_loop_status} in
		( 126 )	die "LOOP find: system error: ${_loop_find_myUtil} could not be executed" ;;
		( 127 )	die "LOOP find: system error: ${_loop_find_myUtil} was not found" ;;
		( $SIGPIPESTATUS )
			;;	# ok: loop exit due to 'break', etc.
		( * )	REPLY=$(command kill -l ${_loop_status} 2>/dev/null) \
			&& not str isint ${REPLY:-0} && REPLY=${REPLY#[Ss][Ii][Gg]} \
			&& case $REPLY in
			( [Tt][Ee][Rr][Mm] )	# if SIGPIPE is ignored, allow SIGTERM
				thisshellhas WRN_NOSIGPIPE \
				|| die "LOOP find: system error: ${_loop_find_myUtil} killed by SIGTERM" ;;
			( * )	 die "LOOP find: system error: ${_loop_find_myUtil} killed by SIG$REPLY" ;;
			esac || die "LOOP find: system error: ${_loop_find_myUtil} failed with status ${_loop_status}" ;;
		esac
	fi

	# 7. Get the main shell to complete the loop with the remembered exit status.
	#    If we have --xargs, first clear the PPs or unset the array.
	if isset _loop_xargs; then
		str empty ${_loop_xargs} && put >&8 "set --; " || put >&8 "unset -v ${_loop_xargs}; "
	fi
	putln "! _loop_E=${_loop_status}" >&8
}

if thisshellhas ROFUNC; then
	readonly -f _loopgen_find
fi
