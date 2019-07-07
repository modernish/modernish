#! helper/script/for/moderni/sh
#
# Determine & validate DEFPATH, the default path for standard POSIX utilities.
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

# wrap this dot script in a function so 'return' works on broken shells
_Msh_testFn() {

case ${DEFPATH+s} in
( '' )	DEFPATH=$(
		PATH=/usr/xpg7/bin:/usr/xpg6/bin:/usr/xpg4/bin:/bin:/usr/bin:$PATH \
			getconf PATH 2>/dev/null
		) \
	|| DEFPATH=/bin:/usr/bin:/sbin:/usr/sbin ;;
esac
case $DEFPATH in
( '' | [!/]* | *:[!/]* | *: )
	echo 'fatal: non-absolute or empty path in DEFPATH' >&2
	return 128 ;;
esac
for _Msh_test in awk cat kill ls mkdir printf ps sed uname; do
	if ! PATH=$DEFPATH command -v "${_Msh_test}" >/dev/null 2>&1; then
		echo 'fatal: cannot find standard utilities in DEFPATH' >&2
		return 128
	fi
done

}
_Msh_testFn
