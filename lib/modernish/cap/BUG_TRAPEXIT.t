#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_TRAPEXIT: the shell's "trap" builtin does not know the EXIT trap by
# name, but only by number (0).
#
# Found in klibc 2.0.4 dash
#
# Note that var/stack/trap effectively works around this bug; its 'trap' and
# 'pushtrap' commands understand the EXIT signal name and give the native
# 'trap' command the signal number 0. So this bug only affects scripters if
# the system 'trap' builtin is used directly.
#
# Cause: this version of dash is patched to omit mksignames.c.
# The functionality of that file was replaced by a simple
# function that does not hardcode the EXIT pseudosignal.
# https://git.kernel.org/pub/scm/libs/klibc/klibc.git/tree/usr/dash/README.dash

! (command trap - EXIT || ! command trap - 0) 2>/dev/null
