#! /shell/quirk/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# QRK_32BIT: the shell only has 32-bit arithmetics. Since every modern
# system these days supports 64-bit long integers even on 32-bit kernels, we
# can now count this as a quirk.
# mksh has it (on purpose). For 64-bit arithmetics, run lksh instead.
case $((2147483650)) in
( 2147483650 ) return 1 ;;
( -2147483646 | 2147483647 ) ;;
( * )	echo "QRK_32BIT.t: Undiscovered bug with 32-bit arithmetic wraparound!" 1>&2
	return 2 ;;
esac
