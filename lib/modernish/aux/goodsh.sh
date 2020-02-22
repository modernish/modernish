#! helper/script/for/moderni/sh
#
# Find a good POSIX-compliant shell, one that passes the fatal.sh bug tests.
# This is used by install.sh, uninstall.sh, and bin/modernish before install
# or when bundled.
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

case ${DEFPATH+s} in
( '' )	. "${MSH_PREFIX:-$PWD}/lib/modernish/aux/defpath.sh" ;;
esac

# Save IFS (field splitting) state.
# Due to BUG_IFSISSET on ksh93, we can't test if IFS is set by any normal method, and we also can't know yet if we're on ksh93
# or not. So use the workaround here, which is to analyse field splitting behaviour (this thankfully works on all shells).
_Msh_testFn() {
	case ${IFS:+n} in	# non-empty: it is set
	( '' )	set -- "a b c"	# empty: test for default field splitting
		set -- $1
		case $# in
		( 1 )	;;	# no field splitting: it is empty and set
		( * )	! : ;;	# default field splitting: it is unset
		esac ;;
	esac
}
_Msh_testFn && _Msh_IFS=$IFS || unset -v _Msh_IFS

# Save pathname expansion state.
case $- in
( *f* )	unset -v _Msh_glob ;;
( * )	_Msh_glob=y ;;
esac

# Function that tests a shell from a subshell.
_Msh_doTestShell() {
	export DEFPATH
	exec "$1" -c \
		'. "$1" && unset -v MSH_FTL_DEBUG && command . "$2" || echo BUG' \
		"$1" \
		"${MSH_PREFIX:-$PWD}/lib/modernish/aux/std.sh" \
		"${MSH_PREFIX:-$PWD}/lib/modernish/aux/fatal.sh" \
		2>|/dev/null
}

# We need some local positional parameters. Set a one-time function to run immediately.
_Msh_testFn() {
# Unless MSH_SHELL is set, try to prefer a shell with KSHARRAY and (DBLBRACKETERE or TESTERE) and (PROCSUBST or PROCREDIR).
# Various aspects of the library use DBLBRACKETERE/TESTERE and KSHARRAY to optimise performance, whereas PROCSUBST/PROCREDIR
# is used as a loop entry performance optimisation in modernish loops (var/loop) by avoiding the need to invoke mkfifo.
# (Note that bash < 5.1 unfortunately refuses to allow PROCSUBST in POSIX mode, but var/loop cheats and uses it anyway.)
set -- zsh ksh93 yash bash ksh lksh mksh ash gwsh dash sh
#					 ^^^^^^^^^^^^^^^^ none of these
#			       ^^^^^^^^^ lksh/mksh: KSHARRAY
#			   ^^^ random ksh (ksh93 or lksh/mksh): KSHARRAY, DBLBRACKETERE?, PROCSUBST?
#		      ^^^^ bash: KSHARRAY, DBLBRACKETERE, PROCSUBSTcheat
#		 ^^^^ yash: TESTERE, PROCREDIR
#      ^^^^^^^^^ zsh, ksh93: KSHARRAY, DBLBRACKETERE, PROCSUBST
case ${MSH_SHELL:+s} in
( s )	case $MSH_SHELL in
	( /* )	case ${MSH_SHELL##*/} in
		( [!0123456789-]*[0123456789-]* )
			# if we have e.g. zsh-5.7.1 or ksh93, also try zsh or ksh in preference
			_Msh_test=${MSH_SHELL##*/}
			set -- "${_Msh_test%%[0123456789-]*}" "$@" ;;
		esac
		# if we have e.g. /usr/local/bin/zsh-5.7.1 or /bin/ksh93, also try zsh-5.7.1 or ksh93 in preference
		set -- "${MSH_SHELL##*/}" "$@" ;;
	esac
	set -- "$MSH_SHELL" "$@" ;;
esac
unset -v MSH_SHELL

IFS=:	# split $DEFPATH and $PATH on ':'
set -f	# no pathname expansion while splitting
for _Msh_test do
	case ${_Msh_test} in
	( /* )	command -v "${_Msh_test}" >/dev/null 2>&1 || continue
		case $(_Msh_doTestShell "${_Msh_test}") in
		( $$ )	MSH_SHELL=${_Msh_test}
			break ;;
		esac ;;
	( * )	for _Msh_P in $DEFPATH $PATH; do
			case ${_Msh_P} in
			( /* )	command -v "${_Msh_P}/${_Msh_test}" >/dev/null 2>&1 || continue
				case $(_Msh_doTestShell "${_Msh_P}/${_Msh_test}") in
				( $$ )	MSH_SHELL=${_Msh_P}/${_Msh_test}
					break 2 ;;
				esac ;;
			esac
		done ;;
	esac
done
unset -v _Msh_test _Msh_P
}
_Msh_testFn

unset -f _Msh_doTestShell _Msh_testFn

# Restore IFS (field splitting) state.
case ${_Msh_IFS+s} in
( '' )	unset -v IFS ;;
( * )	IFS=${_Msh_IFS}
	unset -v _Msh_IFS ;;
esac

# Restore pathname expansion state.
case ${_Msh_glob+s} in
( '' )	set -f ;;
( * )	set +f
	unset -v _Msh_glob ;;
esac

case ${MSH_SHELL:+s} in
( '' )	if PATH=/dev/null command -v _Msh_initExit >/dev/null 2>&1; then
		_Msh_initExit "Can't find any suitable POSIX-compliant shell!"
	fi
	echo "Fatal: can't find any suitable POSIX-compliant shell!" 1>&2
	exit 128 ;;
esac
export MSH_SHELL
