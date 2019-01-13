#! /shell/quirk/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# QRK_SPCBIXP: Variable assignments preceding special builtins
# are exported, and persist as exported. (bash -o posix; yash)
_Msh_test=foo :
isset -x _Msh_test
