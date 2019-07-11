#! /usr/bin/env modernish
#! use safe
#! use sys/cmd/harden
#! use var/loop
#! use sys/base/mktemp
harden cat
harden -e '>1' cmp
harden paste
harden LC_ALL=C sed
harden LC_ALL=C sort

# This is a helper script I use to maintain the 'unalias' commands at the top
# of every lib/modernish/mdl/**/*.mm module file. They are mainly inserted for
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
mdl_reldir=${MSH_MDL#"$MSH_PREFIX/"}
is dir $mdl_reldir || cd $MSH_PREFIX || die
putln "Updating unalias for modules in $PWD/$mdl_reldir"

# --- Prepare temp file ---
mktemp -sCCt unalias_update	# 2x -C = auto-cleanup even on Ctrl+C
mytempfile=$REPLY

# --- Main loop ---
changed=0 total=0
LOOP find modulefile in $mdl_reldir -type f -name *.mm; DO
	let "total += 1"
	# Eliminate comments, get function names from lines like "funcname() {",
	# as well as alias names from lines like 'alias name=...',
	# and make make "_" sort last (change to "~").
	functions=$(
		export LC_ALL=C
		sed -n 's/#.*//
			/[[:alpha:]_][[:alnum:]_]*()[[:blank:]]*[{(]/ {
				h
				s/().*//
				s/^.*[^[:alnum:]_]//
				s/^_/~/
				p
				g
			}
			/alias[[:blank:]]\{1,\}[[:alnum:]_!%,@]\{1,\}=/ {
				s/^.*alias //
				s/=.*//
				s/^_/~/
				p
			}' $modulefile |
		sort -u |
		sed 's/^~/_/' |
		paste -s -d ' ' -	# combine on one line
	)
	str empty $functions && continue
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
		let "changed += 1"
	fi
DONE
putln "$changed out of $total modules updated."
