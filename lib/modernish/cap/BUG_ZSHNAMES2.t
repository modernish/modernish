#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_ZSHNAMES2: Two lowercase variable names 'histchars' and 'signals',
# normally okay for script use as per POSIX convention, are reserved for
# special use on zsh, even if zsh is initialised in sh mode (via a 'sh'
# symlink or using the '--emulate sh' option at startup).
#
# Bug found on: zsh <= 5.7.1.
# See also BUG_ZSHNAMES.

isset histchars || return 1
thisshellhas BUG_ZSHNAMES && return 1	# this bug is included in that one

(
	_Msh_test=$histchars
	{ histchars=á; } 2>/dev/null	# assignment ignored: "zsh:1: HISTCHARS can only contain ASCII characters"
	case $histchars in
	( "${_Msh_test}" )
		;;
	( * )	exit 1 ;;
	esac
) || return 1
