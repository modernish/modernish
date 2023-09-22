#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# Helper script for lib/modernish/cap/BUG_LOOPRET3.t; see there for info

while ! return 13; do
	:
done
