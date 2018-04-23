#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_ARITHINIT: In dash <= 0.5.9.1, compiled on FreeBSD
# or macOS, using unset or empty variables in arithmetic
# expressions causes the shell to error out with an "Illegal number" error.
# Instead, according to POSIX, it should take them as a value of zero.
# Ref.: https://www.spinics.net/lists/dash/msg01370.html
#
# yash <= 2.44 also has a variant of this bug: it is only
# triggered in a simple arithmetic expression containing a single variable
# name without operators, and only if that variable is unset (not if it's
# set but empty). The bug causes yash to exit silently with status 2.
# Ref.: https://osdn.net/ticket/browse.php?group_id=3863&tid=36966

# (_Msh_test below is guaranteed to be unset on entry.)
! (set +u; : $((_Msh_test))) 2>/dev/null
