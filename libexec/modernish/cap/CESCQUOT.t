#! /shell/capability/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# CESCQUOT: Quoting with C-style escapes, like $'\n' for newline.
case $'a\40b' in
( 'a b' ) ;;
( * ) return 1 ;;
esac
