#! /shell/quirk/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# QRK_HDPARQUOT: QUOTes within PARameter substitutions in expading
# Here-Documents aren't removed. For instance, if 'var' is set, ${var+"x"}
# in a here-document yields "x", not x. POSIX considers this form
# unspecified within here-documents.
#
# This means that substitutions such as ${var-"word"} and ${var+"word"}
# should not be used in here-documents; use ${var-word} and ${var+word}
# instead.
#
# Quirk found on: FreeBSD sh, bosh (schily sh)
#
# Note that this does not apply to parameter substitutions that remove
# patterns, such as ${var#"foo"} and ${var%"foo"}; POSIX specifies here
# that the quotes shall be removed so you can escape glob characters,
# so the quotes are safe to use for those.

IFS= read -r _Msh_test <<EOF
${_Msh_test-"word"}
EOF
case ${_Msh_test} in
( \"word\" ) ;;  # got quirk
( word ) return 1 ;;
( * )	echo "QRK_HDPARQUOT.t: internal error: unknown bug with par.subst. in here-doc"
	return 2 ;;
esac
