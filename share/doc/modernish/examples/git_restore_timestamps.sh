#! /usr/bin/env modernish
#! use safe
#! use sys/harden
#! use var/loop
harden git
harden -e '>1' -f wd_is_clean git diff-index --quiet HEAD
harden -pt touch

# Git timestamp restorer. This sets the timestamps on working directory
# files within a local Git repository to the date of the last commit in
# which they were changed. If you first change to a subdirectory of the
# repo, this will only restore the timestamps down from that directory.

if not wd_is_clean; then
	exit 1 'Working directory not clean. Commit or stash changes first.'
fi

LOOP for --split=$CCn repofile in $(git ls-tree -r -t --name-only HEAD)
DO
	if startswith $repofile '../'; then
		# If we're in a subdirectory of the repo, skip parent dirs.
		continue
	elif not is present $repofile; then
		die "File $repofile not in WD! (should never happen)"
	fi

	# Ask Git for latest commit's timestamp formatted for POSIX 'touch -t'.
	timestamp=$(git log --format=%cd \
		--date=format:%Y%m%d%H%M.%S \
		-1 HEAD -- $repofile)

	# The 'touch' command is traced due to 'harden -t' above.
	touch -t $timestamp $repofile
DONE
