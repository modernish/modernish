#! helper/script/for/moderni/sh
#
# Helper script to put the shell in standards mode, if available and desirable.
#
# --- begin license ---
# Copyright (c) 2020 Martijn Dekker <martijn@inlv.org>
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

# ... first, a sanity check
case \
${BASH_VERSION+s}\
${KSH_VERSION+s}\
${NETBSD_SHELL+s}\
${POSH_VERSION+s}\
${SH_VERSION+s}\
${YASH_VERSION+s}\
${ZSH_VERSION+s}\
 in
( s )	;;
( '' )	command set -o posix 2>/dev/null ;;	# Try if a non-identifiable shell has a POSIX option
( * )	_Msh_m="sanity check failed: more than one shell version identifier variable found"
	if PATH=/dev/null command -v _Msh_initExit >/dev/null; then
		_Msh_initExit "${_Msh_m}"
	fi
	echo "${_Msh_m}" 1>&2
	exit 128 ;;
esac

# ... zsh:
case ${ZSH_VERSION+z} in
( z )	case $- in
	( *x* )	emulate -R sh; set -x ;;
	( * )	emulate -R sh ;;
	esac
	# We need POSIX_ARGZERO for correct initialisation in phase 2.
	setopt POSIX_ARGZERO
	# Enable UTF-8 support if we're in such a locale.
	setopt MULTIBYTE	# TODO: remove when we stop supporting zsh 5.0.8
	# On zsh < 5.3, "readonly" works like "typeset -r" even in POSIX mode,
	# meaning readonly variables set in functions are local to functions,
	# which is contrary to our usage and POSIX. Test for that bug and make
	# "readonly" do "typeset -rg" if found, making them global.
	# TODO: remove when we stop supporting zsh < 5.3
	unset -v _Msh_RO
	_Msh_testFn() {
		readonly _Msh_RO=y
	}
	_Msh_testFn
	case ${_Msh_RO-} in
	( y )	unsetopt POSIX_BUILTINS	# allow 'typeset +r'
		typeset +r _Msh_RO
		setopt POSIX_BUILTINS
		unset -v _Msh_RO ;;
	( * )	disable -r readonly 2>/dev/null	# it's a reserved word on zsh 5.2
		disable readonly
		eval 'function readonly { typeset -rg "$@"; }'
		alias readonly='typeset -rg' ;;
		# In stage 2 init at the end of bin/modernish, we'll redefine this alias to
		# be properly conditional upon posixbuiltins. Not doing this now as it comes
		# at the cost of forking a subshell and modernish init doesn't need it.
	esac
	if ! unset -f _Msh_nonexistent_fn 2>/dev/null; then
		# 'unset -f' complains about nonexistent functions (contra POSIX);
		# make it quietly accept them like other shells.
		# TODO: remove when we stop supporting zsh < 5.5
		eval 'function unset {
			case $1 in
			( -f )  builtin unset "$@" 2>/dev/null || : ;;
			( * )	builtin unset "$@" ;;
			esac
		}'
	fi
	# Make zsh even more POSIXy for cross-shell scripts only.
	case $0 in
	( modernish | */modernish )
		# These zsh-specific reserved words may interfere with shell functions.
		disable -r end foreach nocorrect repeat 2>/dev/null
		# These revert to builtins, subject to KSH_TYPESET, which is off by default for sh.
		disable -r declare export float integer local readonly typeset 2>/dev/null
		# Counting line numbers of 'eval' commands is more in line with other shells.
		setopt EVAL_LINENO
		;;
	esac
	;;
esac

# ... pdksh and derivatives (oksh, mksh, lksh, ... ?)
case ${KSH_VERSION:-${SH_VERSION:-}} in
( '@(#)'* )
	set -o posix
	# mksh/lksh have UTF-8 support as of R38, but it needs to be turned on
	# explicitly with 'set -U'; the locale is not detected for scripts,
	# presumably for backwards compatibility with OpenBSD which only
	# supports ASCII. The recipe below is recommended by mksh's man page.
	case ${KSH_VERSION:-} in
	( '@(#)MIRBSD KSH '* | '@(#)LEGACY KSH '* )
		case ${LC_ALL:-${LC_CTYPE:-${LANG:-}}} in
		( *[Uu][Tt][Ff]8* | *[Uu][Tt][Ff]-8* )
			set -U ;;
		( * )	set +U ;;
		esac ;;
	esac
	# Restore POSIX 'hash' and 'type' commands which may have been removed by 'unalias -a'.
	PATH=/dev/null command -v hash >/dev/null || alias hash='\command alias -t'
	PATH=/dev/null command -v type >/dev/null || alias type='\command -V'
	;;
( 'Version '* )
	# ksh 93u+m has a posix option
	test -o \?posix && set -o posix
	;;
esac

# ... yash: The POSIX mode disables most extended shell functionality that scripts might want
# to detect and use. It also makes yash search for an equivalent external utility in $PATH
# before each execution of any regular built-in, which seriously impacts performance. So let's
# leave it off by default. (Enable it manually for a very good POSIX compatibility check.)
case ${YASH_VERSION+s} in
( s )	#set -o posix
	# As of yash 2.49, stop the 'for' loop from making the iteration variable local (BUG_FORLOCAL).
	command set +o forlocal 2>/dev/null ;;
esac

# ... NetBSD sh:
case ${NETBSD_SHELL+n} in
( n )	set -o posix ;;
esac

# ... bash:
case ${BASH_VERSION+b} in
( b )	# Just in case $POSIXLY_CORRECT and -o posix ever get decoupled...
	# Ref.: https://lists.gnu.org/archive/html/bug-bash/2020-01/msg00021.html
	set -o posix
	# As of bash 5.0, we can fix QRK_LOCALUNS2 by setting localvar_unset.
	command shopt -s localvar_unset 2>/dev/null ;;
esac

# ... external commands:
export POSIXLY_CORRECT=y	# this also sets -o posix on bash
