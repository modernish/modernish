#! /usr/bin/env modernish
#! use safe
#! use sys/cmd/harden
#! use var/loop
#! use sys/base/mktemp
harden cat
harden -e '>1' cmp
harden -e '>1' grep
harden paste
harden sed
harden LC_COLLATE=C sort

# This is a helper script I use to maintain the 'unalias' commands at the top
# of every libexec/modernish/**/*.mm module file. They are mainly inserted for
# the benefit of interactive shell users, where aliases are not unlikely to
# interfere with function definitions, causing spurious syntax errors.
# Ref.: https://github.com/modernish/modernish/issues/5
#
# This script greps function names in module files, sorts them, and combines
# them on one line. Without options, it adds or updates unalias commands on the
# second line of each module file, only updating the file if something actually
# changed. With the -r option, it removes these unalias commands.
#
# It is a nice demonstration of the use of the 'find' loop, as well as the
# auto-cleanup option of modernish 'mktemp'.
#
# It depends on one non-POSIX but common 'grep' feature: 'grep -o', which
# prints only the matching characters and not the entire line containing
# them. Thanks to 'harden grep' (see above), this script will instantly die
# if 'grep -o' is not supported by the local implementation, instead of
# continuing to run uselessly and perhaps harmfully.

# --- Parse options ---
showusage() { putln "Usage: $ME [ -r ]" "See comments in script for info."; }
unset -v opt_r
while getopts 'r' opt; do
	case $opt in
	( r )	opt_r= ;;
	( * )	exit -u 1 ;;
	esac
done
shift $((OPTIND-1))
let $# && exit -u 1 'Excess arguments.'

# --- Make sure we're in a modernish tree ---
is dir libexec/modernish || cd $MSH_PREFIX || die

# --- Prepare temp file ---
mktemp -sCCt unalias_update	# 2x -C = auto-cleanup even on Ctrl+C
mytempfile=$REPLY

# --- Main loop ---
LOOP find modulefile in libexec/modernish -type f -name *.mm; DO
	functions=$(
		grep -v '^[[:space:]]*\#' $modulefile |		# eliminate comments
		grep -o '[A-Za-z0-9_]\{1,\}()[[:space:]]*{' |	# get function names
		sed "s/().*{\$// ; s/^_/$CC7F/" |		# make '_' sort last
		sort -u |
		sed "s/^$CC7F/_/" |
		paste -s -d ' ' -				# combine on one line
	)
	empty $functions && continue
	if isset opt_r; then
		message="- Removing unalias from $PWD/$modulefile"
		script="2 { /^\\\\command unalias/ d; }"
	else
		message="- Updating $PWD/$modulefile:${CCn}  $functions"
		script="2 i\\${CCn}\\\\command unalias $functions 2>/dev/null
			2 { /^\\\\command unalias/ d; }"
	fi
	# (The >| operator bypasses the safe mode's noclobber check: we *want*
	# to overwrite. Redirections cannot be covered by 'harden', so check.)
	sed $script $modulefile >| $mytempfile || die
	if ! cmp -s $modulefile $mytempfile; then
		putln $message
		cat $mytempfile >| $modulefile || die
	fi
DONE
