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

# wrap this dot script in a function so 'return' works on broken shells
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

# BUG_FORLOCAL compat: don't do "for MSH_SHELL in [...]"
for _Msh_test do
	if ! command -v "${_Msh_test}" >/dev/null 2>&1; then
		MSH_SHELL=''
		continue
	fi
	case $(	export DEFPATH
		exec "${_Msh_test}" -c \
			'. "$1" && unset -v MSH_FTL_DEBUG && command . "$2" || echo BUG' \
			"${_Msh_test}" \
			"${MSH_PREFIX:-$PWD}/lib/modernish/aux/std.sh" \
			"${MSH_PREFIX:-$PWD}/lib/modernish/aux/fatal.sh" \
			2>|/dev/null
	) in
	( $$ )	MSH_SHELL=$(command -v "${_Msh_test}")
		break ;;
	( * )	MSH_SHELL=''
		continue ;;
	esac
done
case $MSH_SHELL in
( '' )	if PATH=/dev/null command -v _Msh_initExit >/dev/null; then
		_Msh_initExit "Can't find any suitable POSIX-compliant shell!"
	fi
	echo "Fatal: can't find any suitable POSIX-compliant shell!" 1>&2
	return 128 ;;
esac
export MSH_SHELL

}
_Msh_testFn
