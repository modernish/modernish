#! /shell/quirk/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# QRK_BCDANGER: 'break' and 'continue' work across shell function barriers
# (zsh; older bash, dash, yash). This is especially dangerous for var/local
# which internally uses a temporary shell function to try to protect against
# breaking out of the block without restoring global parameters and settings.

_Msh_testFn() {
	command break 2>/dev/null
}

for _Msh_test in 0 1; do
	_Msh_testFn
done
unset -f _Msh_testFn
return "${_Msh_test}"
