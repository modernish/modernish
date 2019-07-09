#! helper/script/for/moderni/sh
#
# Find a good POSIX-compliant shell, one that passes the fatal.sh bug tests.
# This is used by install.sh, uninstall.sh, and bin/modernish before install.
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

# BUG_FORLOCAL compat: don't do "for MSH_SHELL in [...]"
for _Msh_test in "${MSH_SHELL-}" sh /bin/sh ash dash gwsh zsh5 zsh ksh ksh93 lksh mksh yash bash; do
	if ! command -v "${_Msh_test}" >/dev/null 2>&1; then
		MSH_SHELL=''
		continue
	fi
	case $(	export DEFPATH
		exec "${_Msh_test}" -c \
		'case ${ZSH_VERSION+s} in s) emulate sh;; *) (set -o posix) && set -o posix;; esac; unset -v MSH_FTL_DEBUG
		command . "$0" || echo BUG' "${MSH_PREFIX:-$PWD}/lib/modernish/aux/fatal.sh" 2>|/dev/null
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
