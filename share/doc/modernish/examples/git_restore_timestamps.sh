#! /usr/bin/env modernish
#! use safe
#! use sys/cmd/harden
#! use var/loop
harden git
harden -e '>1' -f wd_is_clean git diff-index --quiet HEAD
harden -pt touch

# Git timestamp restorer. This sets the timestamps on working directory
# files within a local Git repository to the date of the last commit in
# which they were changed. If you first change to a subdirectory of the
# repo, this will only restore the timestamps down from that directory.

git status >/dev/null
if not wd_is_clean; then
	exit 1 'Working directory not clean. Commit or stash changes first.'
fi

total=0
LOOP find repofile in . -name .git -prune -o -iterate
DO
	# Ask Git for latest commit's timestamp formatted for POSIX 'touch -t'.
	timestamp=$(git log --format=%cd \
		--date=format:%Y%m%d%H%M.%S \
		-1 HEAD -- $repofile)
	str empty $timestamp && continue

	# The 'touch' command is traced due to 'harden -t' above.
	touch -t $timestamp $repofile
	let "total+=1"
DONE
exit 0 "$total timestamps restored."
