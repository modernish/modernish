#! /module/for/moderni/sh

# var/mapr
#
# mapr (map records): Read delimited records from the standard input, invoking
# a CALLBACK command with each input record as an argument and with up to
# QUANTUM arguments at a time. By default, an input record is one line of text.
#
# Usage:
# mapr [-d DELIM | -D] [-n COUNT] [-s COUNT] [-c QUANTUM] CALLBACK [ARG ...]
#
# Options:
#   -d DELIM	Use the single character DELIM to delimit input records,
#		instead of the newline character.
#   -P		Paragraph mode. Input records are delimited by sequences
#		consisting of a newline plus one or more blank lines, and
#		leading or trailing blank lines will not result in empty
#		records at the beginning or end of the input. Cannot be used
#		together with -d.
#   -n COUNT	Pass at most COUNT records to CALLBACK. If COUNT is 0, all
#		records are passed.
#   -s COUNT	Skip and discard the first COUNT records read.
#   -c QUANTUM	Specify the number of records read between each call to
#		CALLBACK. If -c is not supplied, the default quantum is 5000.
#
# Arguments:
#   CALLBACK	Call the CALLBACK command with the collected arguments each
#		time QUANTUM lines are read. The callback command may be a
#		shell function or any other kind of command. It is a fatal
#		error for the callback command to exit with a status > 0.
#   ARG		If there are extra arguments supplied on the mapr command line,
#		they will be added before the collected arguments on each
#		invocation on the callback command.
#
# --- begin license ---
# Copyright (c) 2017 Martijn Dekker <martijn@inlv.org>, Groningen, Netherlands
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
# --- end license ---

# check for a bug with 'gsub' in Solaris awk that requires extra backslash escaping
case $(putln "a'b'c" | extern -p awk '{ gsub(/'\''/, "'\''\\'\'\''"); print ("'\''")($0)("'\''"); }') in
( "'a'\''b'\''c'" )
	unset -v _Msh_mapr_awkBug ;;
( "'a'''b'''c'" )
	_Msh_mapr_awkBug='\\' ;;
( * )	putln "var/mapr: unknown awk bug detected!" >&2
	return 1 ;;
esac
readonly _Msh_mapr_awkBug

mapr() {
	# ___ begin option parser ___
	# Generated with the command: generateoptionparser -o -f 'mapr' -v '_Msh_Mo_' -n 'P' -a 'dnsc'
	unset -v _Msh_Mo_P _Msh_Mo_d _Msh_Mo_n _Msh_Mo_s _Msh_Mo_c
	forever do
		case ${1-} in
		( -[!-]?* ) # split a set of combined options
			_Msh_Mo__o=${1#-}
			shift
			forever do
				case ${_Msh_Mo__o} in
				( '' )	break ;;
				# if the option requires an argument, split it and break out of loop
				# (it is always the last in a combined set)
				( [dnsc]* )
					_Msh_Mo__a=-${_Msh_Mo__o%"${_Msh_Mo__o#?}"}
					push _Msh_Mo__a
					_Msh_Mo__o=${_Msh_Mo__o#?}
					if not empty "${_Msh_Mo__o}"; then
						_Msh_Mo__a=${_Msh_Mo__o}
						push _Msh_Mo__a
					fi
					break ;;
				esac
				# split options that do not require arguments (and invalid options) until we run out
				_Msh_Mo__a=-${_Msh_Mo__o%"${_Msh_Mo__o#?}"}
				push _Msh_Mo__a
				_Msh_Mo__o=${_Msh_Mo__o#?}
			done
			while pop _Msh_Mo__a; do
				set -- "${_Msh_Mo__a}" "$@"
			done
			unset -v _Msh_Mo__o _Msh_Mo__a
			continue ;;
		( -[P] )
			eval "_Msh_Mo_${1#-}=''" ;;
		( -[dnsc] )
			let "$# > 1" || die "mapr: $1: option requires argument" || return
			eval "_Msh_Mo_${1#-}=\$2"
			shift ;;
		( -- )	shift; break ;;
		( -* )	die "mapr: invalid option: $1" || return ;;
		( * )	break ;;
		esac
		shift
	done
	# ^^^ end option parser ^^^

	# validate/sanitise option values

	if isset _Msh_Mo_P; then
		if isset _Msh_Mo_d; then
			die "mapr: -d and -P cannot be used together" || return
		fi
		# a null RS (record separator) triggers paragraph mode in awk
		_Msh_Mo_d=''
	elif isset _Msh_Mo_d; then
		if let "${#_Msh_Mo_d} != 1"; then
			# TODO: BUG_MULTIBYTE workaround
			die "mapr: -d: input record separator must be one character: ${_Msh_Mo_d}" || return
		fi
	else
		_Msh_Mo_d=$CCn
	fi

	if isset _Msh_Mo_n; then
		if not isint "${_Msh_Mo_n}" || let "_Msh_Mo_n < 0"; then
			die "mapr: -n: invalid number of records: ${_Msh_Mo_n}" || return
		fi
		_Msh_Mo_n=$((_Msh_Mo_n))
	else
		_Msh_Mo_n=0
	fi

	if isset _Msh_Mo_s; then
		if not isint "${_Msh_Mo_s}" || let "_Msh_Mo_s < 0"; then
			die "mapr: -s: invalid number of records: ${_Msh_Mo_s}" || return
		fi
		_Msh_Mo_s=$((_Msh_Mo_s))
	else
		_Msh_Mo_s=0
	fi

	if isset _Msh_Mo_c; then
		if not isint "${_Msh_Mo_c}" || let "_Msh_Mo_c < 1"; then
			die "mapr: -c: invalid number of records: ${_Msh_Mo_c}" || return
		fi
		_Msh_Mo_c=$((_Msh_Mo_c))
	else
		_Msh_Mo_c=5000
	fi

	case $# in
	( 0 )	die "mapr: command expected" || return ;;
	esac

	# construct awk conditions for skip and callback command quantum

	if let _Msh_Mo_s; then
		_Msh_M_ifNotSkip="NR > ${_Msh_Mo_s} "
		if let _Msh_Mo_c==1; then
			_Msh_M_ifQuantum="NR > $((_Msh_Mo_s+1)) "
		else
			_Msh_M_ifQuantum="NR > $((_Msh_Mo_s+1)) && (NR - $((_Msh_Mo_s+1))) % ${_Msh_Mo_c} == 0 "
		fi
	else
		_Msh_M_ifNotSkip=''
		if let _Msh_Mo_c==1; then
			_Msh_M_ifQuantum='NR > 1 '
		else
			_Msh_M_ifQuantum="NR > 1 && (NR - 1) % ${_Msh_Mo_c} == 0 "
		fi
	fi
	
	# construct awk condition for maximum number of records

	if let _Msh_Mo_n; then
		_Msh_M_checkMax="NR >= $((_Msh_Mo_n + _Msh_Mo_s)) {
				exit 0;
			}"
	else
		_Msh_M_checkMax=''
	fi

	# Note: the shell parses the construct below from the inside out, i.e. the stuff within
	# the $(command substitution) is run first. The command substitution uses 'awk' to
	# produce commands ("$@") with shell-quoted arguments to be parsed by 'eval'.

	eval "unset -v _Msh_Mo_P _Msh_Mo_d _Msh_Mo_n _Msh_Mo_s _Msh_Mo_c _Msh_M_ifQuantum _Msh_M_ifNotSkip _Msh_M_checkMax
	$(	export _Msh_Mo_d POSIXLY_CORRECT=y
		extern -p awk '
			BEGIN {
				RS=ENVIRON["_Msh_Mo_d"];
			}
			NR==1 {
				ORS=" ";  # output space-separated arguments
				print "\"$@\"";
			}
			'"${_Msh_M_ifQuantum}"'{
				print "|| { shellquoteparams; die \"mapr: callback failed with status $?: $@\"; return; }\n\"$@\"";
			}
			'"${_Msh_M_ifNotSkip}"'{
				# shell-quote and output the records as arguments
				gsub(/'\''/, "'\''\\'"${_Msh_mapr_awkBug-}"\'\''");
				print ("'\''")($0)("'\''");
			}
			'"${_Msh_M_checkMax}"'
			END {
				if (ORS==" ") {
					ORS="\n";
					print "|| { shellquoteparams; die \"mapr: callback failed with status $?: $@\"; return; }";
				}
			}
		' || die "mapr: 'awk' failed"
	)"
}

if thisshellhas ROFUNC; then
	readonly -f mapr
fi
