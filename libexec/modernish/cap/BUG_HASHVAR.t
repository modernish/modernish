#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_HASHVAR: On zsh, $#var means the length of $var - other shells and
# POSIX require braces, as in ${#var}. This causes interesting bugs when
# combining $#, being the number of positional parameters, with other
# strings. For example, in arithmetics: $(($#-1)), instead of the number of
# positional parameters minus one, is interpreted as ${#-} concatenated with
# '1'. So, for zsh compatibility, always use ${#} instead of $# unless it's
# stand-alone or followed by a space.
# zsh 5.0.8 fixes this bug, but *only* in POSIX/'emulate sh' mode.
_Msh_test=$$	# another bug on zsh 4.3.11 is that ${#$} is a bad
		# substitution, even though $#${var} resolves to ${#$}{var};
		# we're assigning $$ to the variable as a workaround
case $#${_Msh_test},$(($#-1+1)) in
# expected result:
# "${#}${$},${#}"
( "${#_Msh_test}{_Msh_test},${#-}2" | "${#_Msh_test}{_Msh_test},2" )
	# the second bug pattern applies if ${#-} is zero (i.e. no shell
	# options active); this happens if zsh is launched as 'sh'
	;;
( * )	return 1 ;;
esac
