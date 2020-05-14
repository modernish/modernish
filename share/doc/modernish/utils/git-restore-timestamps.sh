#! /usr/bin/env modernish
#! use safe -k
#! use sys/cmd/harden
#! use var/loop/find -b

# Git timestamp restorer. This sets the timestamps on working directory
# files within a local Git repository to the date of the last commit in
# which they were changed. If you first change to a subdirectory of the
# repo, this will only restore the timestamps down from that directory.
#
# By Martijn Dekker <martijn@inlv.org> 2019-2020. Public domain.

# Harden commands used, including three variants of 'git'.
# Add the -t option to any command you'd like to trace.
harden git
harden -e '>1' -f wd_is_clean git diff-index --quiet HEAD
harden -t -e '>1' -f is_ignored git check-ignore --quiet
harden -pt touch

# --- Prepare ---

git status >/dev/null # this is sometimes needed to convince git its WD is clean
if not wd_is_clean; then
	exit 1 'Working directory not clean. Commit or stash changes first.'
fi

# --- Main loop ---
#
# 'LOOP find' fully integrates the 'find' utility into the shell. It can
# even -exec a shell function in the main shell environment right from the
# 'find' expression, which (unlike commands from the loop body) is capable
# of physically influencing the find utility's directory traversal.
#
# Below, we use the is_ignored() function (defined using 'harden' above)
# with -prune to avoid descending into directories ignored in '.gitignore'.
# The advantage is that command hardening is effective: the program dies if
# 'git' fails (yields an exit status > 1). The regular 'find' utility would
# interpret a command failure as a simple false result and keep right on
# going. Depending on what your program does, that can be dangerous.
#
# As it's usually pointless to check if sub-sub-sub-sub-subdirectories are
# ignored, and checking this for the repo's root directory is even more
# pointless, we also use the BSD-style '-depth n' primary to only check
# is_ignored for directories 1 through 3 levels deep, inclusive. Modernish
# internally translates '-depth n' to a portable equivalent so it works
# with any local POSIX-compliant 'find' utility.
#
# Export _loop_DEBUG=y if you're curious to see how 'LOOP find' translates
# its invocation to a command line for the system's 'find' utility. This
# will reveal the paths to the helper scripts it uses to work its magic.

total=0
LOOP find repofile in . \
	-name .git -prune \
	-or -type d -depth +0 -depth -4 -exec is_ignored {} \; -prune \
	-or -iterate
DO
	# Ask Git for latest commit's timestamp formatted for POSIX 'touch -t'.
	# This is the performance bottleneck; searching git logs is expensive.
	timestamp=$(git log --format=%cd \
		--date=format:%Y%m%d%H%M.%S \
		-1 HEAD -- $repofile)
	str empty $timestamp && continue

	# The 'touch' command is traced due to 'harden -t' above.
	touch -t $timestamp $repofile
	let "total+=1"
DONE
exit 0 "$total timestamps restored."
