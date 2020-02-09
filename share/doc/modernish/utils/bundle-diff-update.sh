#! /usr/bin/env modernish
#! use safe
#! use sys/base/mktemp
#! use sys/cmd/harden
#! use sys/cmd/procsubst
#! use var/loop
#! use var/string/replacein

# Maintenance script for lib/_install/**/*.bundle.diff.
#
# This utility checks if all the diffs still apply. If not, it leaves *.rej files for manual resolution.
# Diffs that apply with an offset or with fuzzing are regenerated and written back to the source tree.

# Harden all utilities used, so the script reliably dies on failure.
# (To trace this script's important actions, add the '-t' option to every harden command)
harden cat
harden -e '>1' cmp
harden -e '>1' diff
harden -e '>1' patch
harden rm
harden sed
harden -P -f skip_headerlines sed '1,2 d'	# -P = whitelist SIGPIPE

mktemp -sdC '/tmp/diff.'; tmpdir=$REPLY
is reg lib/_install/bin/modernish.bundle.diff || chdir $MSH_PREFIX
total=0 updated=0 failures=0

LOOP find bundlediff in lib/_install -type f -name *.bundle.diff
DO
	let "total += 1"

	# The directory paths of the diffs correspond to those of the original files.
	origfile=${bundlediff#lib/_install/}
	origfile=${origfile%.bundle.diff}

	tmpfile=$origfile
	replacein -a tmpfile / :
	tmpfile=$tmpdir/$tmpfile

	# Attempt to apply the diff into $tmpfile.
	patch_output=$(patch -i $bundlediff -o $tmpfile $origfile 2>&1)
	if not so; then
		putln "" "!!! The diff for $origfile FAILED:" $patch_output ""
		let "failures += 1"
		continue
	fi

	# Regenerate the diff. Determine if it changed by comparing everything except the two header lines.
	diff -u $origfile $tmpfile > $tmpfile.diff
	cmp -s $(% skip_headerlines $bundlediff) $(% skip_headerlines $tmpfile.diff)
	if not so; then
		putln "--- UPDATING $bundlediff"
		# Change the useless temporary filename in the new diff to the original filename.
		sed "2 s:^+++ [^$CCt]*:+++ $origfile:" $tmpfile.diff > $tmpfile.ndiff
		# Update the bundle.diff in the source tree.
		cat $tmpfile.ndiff >| $bundlediff || die "can't overwrite $bundlediff"
		let "updated += 1"
	else
		putln "--- $bundlediff is up to date"
	fi
	rm -f $tmpfile $tmpfile.diff $tmpfile.ndiff &
DONE

putln "$updated out of $total diffs updated."

if let failures; then
	putln "$failures failed. Manually apply the *.rej files and update the diff(s)." \
		"The directory with partially-patched files and *.rej files is:" $tmpdir >&2
	poptrap EXIT	# remove mktemp's autocleanup trap
	exit 1
fi
