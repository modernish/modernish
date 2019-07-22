#! helper/script/for/moderni/sh
#
# Helper script to identify the version of this shell, if possible.
# Used (sourced, 'dotted') by install.sh and tst/run.sh, but also
# works independently if invoked like 'modernish id.sh'.
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

case ${MSH_VERSION+s} in
( '' )	echo "$0: Requires modernish." >&2
	exit 128 ;;
esac

# Functionality starts here.
case \
${BASH_VERSION+ba}${KSH_VERSION+k}${NETBSD_SHELL+n}${POSH_VERSION+po}${SH_VERSION+k}${YASH_VERSION+ya}${ZSH_VERSION+z} \
in
( ya )	putln "* This shell identifies itself as yash version $YASH_VERSION" ;;
( k )	isset KSH_VERSION || KSH_VERSION=$SH_VERSION
	case $KSH_VERSION in
	( '@(#)MIRBSD KSH '* )
		putln "* This shell identifies itself as mksh version ${KSH_VERSION#*KSH }." ;;
	( '@(#)LEGACY KSH '* )
		putln "* This shell identifies itself as lksh version ${KSH_VERSION#*KSH }." ;;
	( '@(#)PD KSH v'* )
		putln "* This shell identifies itself as pdksh version ${KSH_VERSION#*KSH v}."
		if str end "$KSH_VERSION" 'v5.2.14 99/07/13.2'; then
			putln "  (Note: many different pdksh variants carry this version identifier.)"
		fi ;;
	( Version* )
		putln "* This shell identifies itself as AT&T ksh93 v${KSH_VERSION#V}." ;;
	( 2[0-9][0-9][0-9].* )
		putln "* This shell identifies itself as AT&T ksh93 version $KSH_VERSION." ;;
	( * )	putln "* WARNING: This shell has an unknown \$KSH_VERSION identifier: $KSH_VERSION." ;;
	esac ;;
( z )	putln "* This shell identifies itself as zsh version $ZSH_VERSION." ;;
( ba )	putln "* This shell identifies itself as bash version $BASH_VERSION." ;;
( po )	putln "* This shell identifies itself as posh version $POSH_VERSION." ;;
( n )	putln "* This shell identifies itself as NetBSD sh version $NETBSD_SHELL." ;;
( * )	if (eval '[[ -n ${.sh.version+s} ]]') 2>/dev/null; then
		eval 'putln "* This shell identifies itself as AT&T ksh93 v${.sh.version#V}."'
	else
		putln "* This is a POSIX-compliant shell without a known version identifier variable."
	fi ;;
esac

# opt_q is the '-q' option from tst/run.sh
if not isset opt_q || let "opt_q < 1"; then
	putln "  Modernish detected the following bugs, quirks and/or extra features on it:"
	thisshellhas --cache
	(PATH=$DEFPATH; thisshellhas --show | sed 's/^/  /' | pr -5 -t -w80)
fi
