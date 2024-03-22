#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_APPENDC: On zsh < 5.1, when set -C (noclobber) is active, "appending" to
# a nonexistent file with '>>' throws an error rather than creating the file.
# This is long-standing zsh behaviour, but is contrary to the POSIX spec and
# different from every other shell, so it's a legit POSIX compliance bug.
# The error may cause the shell to exit, so must fork a subshell to test it.
# This is another bug affecting 'use safe'.
# Ref.: http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_07_03
#	http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_25

! (
	unset -v _Msh_D _Msh_i
	command umask 077
	PATH=$DEFPATH
	unset -f rm	# QRK_EXECFNBI compat
	command trap 'exec rm -rf "${_Msh_D-}" &' 0 INT PIPE TERM	# BUG_TRAPEXIT compat
	_Msh_i=${RANDOM:-0}
	_Msh_tmp=${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}
	until _Msh_D=${_Msh_tmp}/_Msh_BUG_APPENDC.$$.${_Msh_i}; command mkdir "${_Msh_D}" 2>/dev/null; do
		let "$? > 125" && die "BUG_APPENDC.t: system error: 'mkdir' failed"
		is -L dir "${_Msh_tmp}" && can write "${_Msh_tmp}" \
		|| die "BUG_APPENDC.t: system error: ${_Msh_tmp} directory not writable"
		_Msh_i=$((_Msh_i+1))
	done
	# Test if "appending" under 'set -C' creates a file
	set -C
	{ command : >> "${_Msh_D}/file"; } 2>/dev/null
	is reg "${_Msh_D}/file"
)
