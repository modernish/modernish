# Modernish code examples #

*This file is under construction.*

This file aims to demonstrate modernish by showing side-by-side comparisons
of plain POSIX shell script and modernish script.

For documentation, see [README.md](https://github.com/modernish/modernish/blob/master/README.md).

## Git timestamp restorer ##

This script sets the timestamps on working directory files within a local
Git repository to the date of the last commit in which they were changed. If
you first change to a subdirectory of the repo, it will only restore the
timestamps down from that directory.

<table>
<tr><th align="left">Plain POSIX sh version</th><th align="left">Modernish version</th></tr>
<tr>
<td valign="top">

```sh {.line-numbers}
#! /bin/sh







git status >/dev/null || exit
if ! git diff-index --quiet HEAD; then
	echo 'Working directory not clean.' >&2
	exit 1
fi

find . -name .git -prune -o -exec sh -c '
	# Ask Git for latest commit'\''s timestamp,
	# formatted for POSIX '\''touch -t'\''.
	timestamp=$(git log --format=%cd \
		--date=format:%Y%m%d%H%M.%S \
		-1 HEAD -- "$1") || exit
	[ -z "$timestamp" ] && exit

	set -x
	touch -t "$timestamp" "$1"
' dummy {} \;
```

</td>
<td valign="top">

```sh {.line-numbers}
#! /usr/bin/env modernish
#! use safe
#! use sys/cmd/harden
#! use var/loop
harden git
harden -e '>1' -f wd_is_clean git diff-index --quiet HEAD
harden -pt touch

git status >/dev/null
if not wd_is_clean; then
	exit 1 'Working directory not clean.'
fi

total=0
LOOP find repofile in . -name .git -prune -or -iterate; DO
	# Ask Git for latest commit's timestamp,
	# formatted for POSIX 'touch -t'.
	timestamp=$(git log --format=%cd \
		--date=format:%Y%m%d%H%M.%S \
		-1 HEAD -- $repofile)
	str empty $timestamp && continue

	# 'touch' is traced due to 'harden -t' above.
	touch -t $timestamp $repofile
	let "total+=1"
DONE
exit 0 "$total timestamps restored."
```

### Discussion ###

TODO

</td>
</tr>
</table>
