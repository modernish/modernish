#! /shell/quirk/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# QRK_HDPARQUOT: Double QUOTes within PARameter substitutions in expanding
# Here-Documents aren't removed. For instance, if 'var' is set, ${var+"x"}
# in a here-document yields "x", not x. POSIX considers this form
# unspecified within here-documents.
#
# Notes:
# - The behaviour with single quotes varies so widely among shells that a quirk
#   test for those is pointless; it is unspecified and they should never be
#   used in this context. But the non-removal of double quotes (as above) only
#   occurs on a couple of shells, so is worth identifying.
# - None of this applies to the use of double quotes in parameter substitutions
#   that remove patterns, such as ${var#"foo"} and ${var%"foo"}; POSIX
#   specifies here that the double quotes shall be removed so you can escape
#   glob characters, so the double quotes are safe to use for those.
#
# Quirk found on: FreeBSD sh, bosh (schily sh)
#
# https://www.mail-archive.com/austin-group-l@opengroup.org/msg01626.html
# XCU 2.7.4 Here-Document:
# ] If no part of word is quoted, all lines of the here-document shall be
# ] expanded for parameter expansion, command substitution, and arithmetic
# ] expansion. In this case, the <backslash> in the input behaves as the
# ] <backslash> inside double-quotes (see Section 2.2.3). However, the
# ] double-quote character ('"') shall not be treated specially within a
# ] here-document, except when the double-quote appears within "$()",
# ] "``", or "${}".

(
command umask 077  # BUG_HDOCMASK compat
IFS= read -r _Msh_test <<EOF
${_Msh_test-"word"}
EOF
case ${_Msh_test} in
( \"word\" ) ;;  # got quirk
( * )	return 1 ;;
esac
)
