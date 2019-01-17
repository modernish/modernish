#! helper/script/for/moderni/sh
#
# Find a good awk utility, one that supports ERE character classes and bounds.
# This is used by install.sh, and bin/modernish before install.
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

# We cannot use 'str match' or 'can exec' yet at the stage of init where modernish calls this script.

# check if this has been done before by a parent shell
case ${_Msh_install_goodawk-} in
( /*/*awk )
	shellquote "_Msh_awk=${_Msh_install_goodawk}"
	return ;;
esac
# do an exhaustive PATH search
push IFS -f -C -u
IFS=''; set -f -C -u  # safe mode
unset -v _Msh_awk
for _Msh_u in awk gawk nawk mawk; do
	_Msh_done=:
	IFS=':'; for _Msh_dir in $DEFPATH ${_Msh_PATH-} $PATH; do IFS=
		case ${_Msh_dir} in (/*) ;; (*) continue;; esac
		case ${_Msh_done} in (*:"${_Msh_dir}":*) continue;; esac
		_Msh_awk=${_Msh_dir}/${_Msh_u}
		if test -f "${_Msh_awk}" && test -x "${_Msh_awk}"; then
			# check that awk supports character classes and bounds
			"${_Msh_awk}" 'BEGIN { exit(!match("/#!","^[[:punct:]]{3}$")); }' 2>/dev/null && break 2
		fi
		_Msh_done=${_Msh_done}${_Msh_dir}:
		unset -v _Msh_awk
	done
done
unset -v _Msh_done _Msh_dir _Msh_u
pop IFS -f -C -u
# if there is a result, export it to any child shells & shellquote it for the current shell (otherwise return 1)
isset _Msh_awk && export "_Msh_install_goodawk=${_Msh_awk}" && shellquote _Msh_awk
