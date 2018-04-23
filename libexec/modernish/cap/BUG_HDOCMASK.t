#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_HDOCMASK (Here-DOCument Mask):
# Here-documents fail if umask cause the creation of a read-only file.
# Workaround: make sure umask is user writable before using here-documents
# (or here-strings [see HERESTRING], which are a special kind of here-doc).
#
# Bug found on bash, mksh, zsh
# Ref.: https://lists.gnu.org/archive/html/bug-bash/2018-03/msg00064.html

(umask a+rw,u-r; : <<-EOF
	EOF
) 2>/dev/null && return 1 || return 0
