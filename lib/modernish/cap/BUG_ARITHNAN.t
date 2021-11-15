#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_ARITHNAN: In ksh <= 93u+m 2021-11-15 and zsh 5.6 - 5.8, the case-insensitive
# floating point constants Inf and NaN are recognised in arithmetic evaluation,
# overriding any variables with the names Inf, NaN, INF, nan, etc.

! (
	# Test by trying arithmically to assign to NaN. This will be a false positive if NaN is a
	# readonly variable. There's no good way around that. Another way would be to check if $((NaN))
	# matches [Nn][Aa][Nn], but in POSIX that variable can legitimately have a value matching that.
	# So we'd have to assign a known value before testing, which fails on readonly again.
	: $((NaN=0))
) 2>/dev/null
