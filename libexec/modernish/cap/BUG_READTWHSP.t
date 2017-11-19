#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_READTWHSP: 'read' does not trim trailing IFS whitesace if there is
# more than one field. (dash) https://bugs.debian.org/794965
# (NOTE: in here-document below: two trailing spaces!)
IFS=' ' read _Msh_test <<-EOF
ab  cd  
EOF
case ${_Msh_test} in
('ab  cd  ')	;;
( * )		return 1 ;;
esac
