#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_ALIASCSHD: parsing problem in dash where alias expansion breaks if a
# here-document containing a command substitution is used within two aliases
# that define a block. This causes a syntax error about a missing '}'
# because the alias terminating the block is not correctly expanded.
#
# This bug affects var/local (LOCAL...BEGIN...END) and var/loop
# (LOOP...DO...DONE). Workaround: make a shell function that handles the
# here-document and call that shell function from the block/loop instead.
#
# Found on: dash <= 0.5.10.2; Busybox ash <= 1.31.1
# Ref.: https://www.spinics.net/lists/dash/msg01909.html

! (
	command alias _Msh_1='{ ' _Msh_2='}'
	eval '_Msh_1
		: || : <<-EOF
		$( : )
		EOF
	_Msh_2'
) 2>/dev/null
