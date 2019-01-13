#! /module/for/moderni/sh
\command unalias _loopgen_for 2>/dev/null
#
# modernish loop/for
#
# This module provides a powerful loop iteration generator (see var/loop.mm)
# for a 'for' loop in several different variants. It also works together
# with the loop/for/select module to provide a 'select' menu loop.
#
# Loop styles provided here are:
# - Enumerative 'for'/'select' loop with safe split/glob operators!
# - MS BASIC-style arithmetic 'for' loop
# - C-style arithmetic 'for' loop
#
# Documentation and usage is too extensive for comments here. Please see
# see commented code below, or README.md under 'use loop', or online at:
# https://github.com/modernish/modernish#user-content-use-loop
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

use var/loop

thisshellhas BUG_ARITHTYPE  # cache it for _loopgen_for()

# This loop generator may be called as 'LOOP for', or (via _loopgen_select() in
# loop/select) as 'LOOP select'.
#
# TODO: --gsplit=PATTERN (split on string matching the glob pattern)
#	--rsplit=REGEX   (same, for an extended regular expression)

_loopgen_for() {
	_loop_type=$1
	shift
	unset -v _loop_glob _loop_split _loop_E
	while	case ${1-} in
		( -- )		shift; break ;;
		( --split )	_loop_split= ;;
		( --split= )	unset -v _loop_split ;;
		( --split=* )	_loop_split=${1#--split=} ;;
 		( --glob )	_loop_glob= ;;
		( --fglob )	_loop_glob=f ;;
		( -* )		_loop_die "unknown option: $1" ;;
		( * )		break ;;
		esac
	do
		shift
	done

	case ${_loop_type},${#},${2-},${4-} in
	# ------
	# Enumerative: LOOP [ for | select ] [ <split/glob-operators> ] <var> in <item1> <item2> ...; DO ...
	( for,*,in,* | select,*,in,* )
		_loop_checkvarname ${_loop_type} $1
		if isset _loop_split || isset _loop_glob; then
			put >&8 'if ! isset -f || ! isset IFS || ! str empty "$IFS"; then' \
					"die 'LOOP ${_loop_type}:" \
						"${_loop_split+--split }${_loop_glob+--${_loop_glob}glob }without safe mode';" \
				'fi; '
		fi
		_loop_V=$1
		shift 2
		# --- Apply split and glob/fglob to the PPs. ---
		if isset _loop_split; then
			if str empty ${_loop_split}; then
				# Unset IFS to get default fieldsplitting.
				while isset IFS; do unset -v IFS; done	# QRK_LOCALUNS/QRK_LOCALUNS2 compat
			else
			#	# BUG_IFSCC01PP/BUG_IFSGLOBC/BUG_IFSGLOBP/BUG_IFSGLOBS compat:
			#	# Split characters could be given that break modernish, so delay this:
			#	IFS=${_loop_split}
				IFS=''
			fi
		fi
		if isset _loop_glob; then
			set +o noglob
		fi
		if isset _loop_split || isset _loop_glob; then
			# With split and/or glob now globally active, any unquoted expansions will apply
			# them -- except within 'case'...'in', in 'case' patterns, and shell assignments.
			_loop_clearPPs=y
			for _loop_A do
				isset _loop_clearPPs && set --  && unset -v _loop_clearPPs  # 'for' uses a copy of the PPs
				unset -v _loop_AA
				not str empty "${_loop_split-}" && IFS=${_loop_split} # BUG_IFS* compat: delayed as per above
				for _loop_AA in ${_loop_A}; do
				#		^^^^^^^^^^ This unquoted expansion does the splitting and/or globbing.
					IFS=''					  # BUG_IFS* compat: unbreak modernish
					case ${_loop_glob-NO} in
					( '' )	is present "${_loop_AA}" || continue ;;
					( f )	if not is present "${_loop_AA}"; then
							shellquote -f _loop_AA
							_loop_die "${_loop_type}: --fglob: no match: ${_loop_AA}"
						fi ;;
					esac
					case ${_loop_glob+G},${_loop_AA} in
					( G,-* | G,\( | G,\! )
						# Avoid accidental parsing as option/operand in various commands.
						_loop_AA=./${_loop_AA} ;;
					esac
					set -- "$@" "${_loop_AA}"
				done
				if not isset _loop_AA && not str id "${_loop_glob-NO}" ''; then
					# Preserve empties. (The shell did its empty removal thing before
					# invoking the loop, so any empties left must have been quoted.)
					str id "${_loop_glob-NO}" f && _loop_die "${_loop_type}: --fglob: empty pattern"
					set -- "$@" ''  
				fi
			done
			case ${#},${_loop_glob-NO} in
			( 0, )	putln '! _loop_E=103' >&8; exit ;;
			( 0,f ) _loop_die "${_loop_type}: --fglob: no patterns" ;;
			esac
			IFS=''; set -o noglob
		fi
		let "$# == 0" && exit
		# --- Write iterations. ---
		if str id ${_loop_type} 'select'; then
			_loop_select_iterate "$@"   # see var/loop/select.mm
		else
			# Generate shell variable assignments, one per line.
			for _loop_A do
				shellquote _loop_A
				putln ${_loop_V}=${_loop_A} || exit
			done >&8 2>/dev/null
		fi ;;
	# ------
	# C style: LOOP for "EXPR; EXPR; EXPR"; DO ...
	( for,1,, )
		case +$1 in
		( *[!_$ASCIIALNUM]_loop_* | *[!_$ASCIIALNUM]_Msh_* )
				_loop_die "for: cannot use _Msh_* or _loop_* internal namespace" ;;
		( *\;*\;*\;* )	_loop_die "for: arithmetic: too many expressions (3 expected in 1 argument)" ;;
		( *\;*\;* )	;;
		( * )		_loop_die "for: arithmetic: too few expressions (3 expected in 1 argument)" ;;
		esac
		str empty ${_loop_glob+s}${_loop_split+s} || _loop_die "for: arithmetic: --split/--*glob not applicable"
		# Split the argument into three.
		_loop_1=$1\;  # add extra ; as non-whitespace IFS is terminator, not separator (except w/ QRK_IFSFINAL)
		IFS=\;
		set -- ${_loop_1}
		IFS=
		# Validate and shellquote the expressions, or apply defaults (1 and 3 empty, 2 is '1' (true)).
		# Since non-builtin modernish 'let' will exit on error, trap EXIT.
		command trap '_loop_die "for: invalid arithmetic expression"' 0	# BUG_TRAPEXIT compat
		case $1 in (*[!$WHITESPACE]*) let "$1" "1" || exit; _loop_1=$1; shellquote _loop_1 ;; ( * ) _loop_1= ;; esac
		case $2 in (*[!$WHITESPACE]*) let "$2" "1" || exit; _loop_2=$2; shellquote _loop_2 ;; ( * ) _loop_2='1' ;; esac
		case $3 in (*[!$WHITESPACE]*) let "$3" "1" || exit; _loop_3=$3; shellquote _loop_3 ;; ( * ) _loop_3= ;; esac
		command trap - 0						# BUG_TRAPEXIT compat
		# Write initial iteration.
		putln "let ${_loop_1} ${_loop_2}" >&8 || die "LOOP for: can't put init"
		# Write further iterations until interrupted.
		forever do
			putln "let ${_loop_3} ${_loop_2}" || exit
		done >&8 2>/dev/null ;;
	# ------
	# BASIC style: LOOP for VAR=EXPR to EXPR [ step EXPR ]; DO ...
	( for,3,to, | for,5,to,step )
		# Validate syntax.
		str empty ${_loop_glob+s}${_loop_split+s} || _loop_die "for: basic: --split/--*glob not applicable"
		case +$1+$3+${5-} in 
		( *[!_$ASCIIALNUM]_loop_* | *[!_$ASCIIALNUM]_Msh_* )
			_loop_die "for: cannot use _Msh_* or _loop_* internal namespace" ;;
		esac
		str match $1 '?*=?*' || _loop_die "for: syntax error: invalid assignment argument"
		_loop_var=${1%%=*}
		_loop_ini="${_loop_var} = (${1#*=})"
		# Validate arith expressions. Since this subshell may force-exit on error, trap EXIT.
		# TODO: find some way to validate in a way that generates more useful error messages.
		command trap '_loop_die "for: invalid arithmetic expression"' 0	# BUG_TRAPEXIT compat
		if let "$# == 5"; then
			let "${_loop_ini}" "_loop_fin = ($3)" "_loop_inc = ($5)" "1" || exit
		else
			let "${_loop_ini}" "_loop_fin = ($3)" "_loop_inc = (${_loop_var} > _loop_fin ? -1 : 1)" || exit
		fi
		command trap - 0						# BUG_TRAPEXIT compat
		let "_loop_inc >= 0" && _loop_cmp='<=' || _loop_cmp='>='
		# Write initial iteration.
		thisshellhas BUG_ARITHTYPE && put "${_loop_var}=''; " >&8
		_loop_expr="(${_loop_ini}) ${_loop_cmp} ($3)"
		shellquote _loop_expr
		putln "let ${_loop_expr}" >&8 || die "LOOP for: can't put init"
		# Write further iterations until interrupted.
		_loop_expr="(${_loop_var} += ${_loop_inc}) ${_loop_cmp} ($3)"
		shellquote _loop_expr
		forever do
			putln "let ${_loop_expr}" || exit
		done >&8 2>/dev/null ;;
	# ------
	# Unknown 'for' loop type.
	( * )	_loop_die "${_loop_type}: syntax error" ;;
	esac
}

if thisshellhas ROFUNC; then
	readonly -f _loopgen_for
fi
