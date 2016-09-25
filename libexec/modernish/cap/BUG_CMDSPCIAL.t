#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_CMDSPCIAL: zsh; mksh < R50e: 'command' does not turn off the 'special
# built-in' characteristics of special built-ins, such as exit shell on error.
# Ref.:	http://pubs.opengroup.org/onlinepubs/9699919799/utilities/command.html#tag_20_22
#	"If the command_name is the same as the name of one of the special
#	built-in utilities, the special properties in the enumerated list at
#	the beginning of Special Built-In Utilities shall not occur."
# Hopefully -@ is an invalid option on every shell...
! ( command set -@; : ) 2>| /dev/null
