#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_UNSETXP: When the allexport shell option is active, the shell's 'unset'
# command incorrectly causes the variable name to gain the export attribute.
#
# https://lore.kernel.org/dash/ac893750-085d-421a-b296-a182ae51f1ec@gigawatt.nl/
#
# Bug found on:
# - dash

push -o allexport
set -o allexport
unset _Msh_test
isset -x _Msh_test
pop --keepstatus -o allexport
