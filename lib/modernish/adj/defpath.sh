#! helper/script/for/moderni/sh
#
# Determine & validate DEFPATH, the default path for standard POSIX utilities.
# This is used by install.sh, and bin/modernish before install or when bundled.
#
# --- begin license ---
# Copyright (c) 2019 Martijn Dekker <martijn@inlv.org>
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
		# support Android/Termux, NixOS, Solaris/illumos, generic /bin:/usr/bin
		PATH=/data/data/com.termux/files/usr/bin:/run/current-system/sw/bin:/usr/xpg7/bin:/usr/xpg6/bin:/usr/xpg4/bin:/bin:/usr/bin:$PATH
		exec getconf PATH 2>/dev/null
	)

	case $DEFPATH in
	( '' )	if test -d /data/data/com.termux/files/usr/bin && test "$(/bin/uname -o 2>/dev/null)" = Android; then
			# Android/Termux: getconf(1) doesn't know 'PATH'.
			DEFPATH=/bin:/data/data/com.termux/files/usr/bin
		else
			# This default should work for most old systems without getconf(1).
			DEFPATH=/bin:/usr/bin:/sbin:/usr/sbin
		fi
	esac

	# Fix for NixOS. Not all POSIX standard utilities come with the default system,
	# e.g. 'bc', 'file', 'vi'. The command that NixOS recommends to get missing
	# utilities, e.g. 'nix-env -iA nixos.bc', installs them in a default profile
	# directory that is not in $(getconf PATH). So add this path to $DEFPATH.
	# See: https://github.com/NixOS/nixpkgs/issues/65512
	if test -e /etc/NIXOS && test -d /nix/var/nix/profiles/default/bin; then
		case :$DEFPATH: in
		( *:/nix/var/nix/profiles/default/bin:* )
			# nothing to do
			;;
		( * )	# insert the default profile directory as the second entry
			case $DEFPATH in
			( *:* )	DEFPATH=${DEFPATH%%:*}:/nix/var/nix/profiles/default/bin:${DEFPATH#*:} ;;
			( * )	DEFPATH=$DEFPATH:/nix/var/nix/profiles/default/bin ;;
			esac
		esac
	fi

	# Fix for AIX. At least as of version 7.1, the system default 'find', 'diff -u' and 'patch' utilities
	# are broken and/or non-compliant in a ways that makes them incompatible with modernish. However, GNU
	# utilities are commonly installed in /opt/freeware/bin, and under standard names (no g- prefix).
	if test -d /opt/freeware/bin; then
		case $(PATH=$DEFPATH command uname) in
		( AIX )	DEFPATH=/opt/freeware/bin:$DEFPATH ;;
		esac
	fi
	;;
esac

# Remove empty and duplicate paths. This is most likely with a user-supplied
# default path, but even 'getconf PATH' output is sometimes buggy.
DEFPATH=$(
	PATH=$DEFPATH
	DEFPATH=
	set -f	 # disable glob for safe split
	IFS=':'	 # split $PATH on ':'
	for _Msh_test in $PATH; do
		case ${_Msh_test} in ( '' ) continue;; esac
		case :$DEFPATH: in ( *:"${_Msh_test}":* ) continue;; esac
		DEFPATH=${DEFPATH:+$DEFPATH:}${_Msh_test}
	done
	printf '%s\nX' "$DEFPATH"
)
DEFPATH=${DEFPATH%?X}

# Validate.
case $DEFPATH in
( '' | [!/]* | *:[!/]* | *: )
	echo 'fatal: non-absolute path in DEFPATH' >&2
	return 128 ;;
esac
for _Msh_test in awk cat kill ls mkdir printf ps sed uname; do
	if ! PATH=$DEFPATH command -v "${_Msh_test}" >/dev/null 2>&1; then
		echo 'fatal: cannot find standard utilities in DEFPATH' >&2
		return 128
	fi
done

# end of wrapper function
}
_Msh_testFn
