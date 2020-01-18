#! /usr/bin/env modernish
#! use safe -k
#! use sys/cmd/harden

# This tests command hardening (sys/cmd/harden module).
# See README.md under "Modules" -> "use sys/cmd/harden" for more info.

harden -tPe '> 1' grep	# harden and trace grep, whitelisting SIGPIPE
harden -tf'no_op' :	# harden ':' as 'no_op' and trace

# if the shell supports it, show the function code
{ typeset -f grep || type grep; } 2>/dev/null

putln '' '--- Test 1'
putln abcde | grep bcd
if so; then putln "test 1 found, GOOD"; fi

putln '' '--- Test 2'
putln abcde | grep xyz
if not so; then putln "test 2 not found, GOOD"; fi

putln '' '--- Test 3'
# Fun fact: harden's -t (trace) option reveals that AT&T ksh93 has some kind
# of optimisation where it would execute the 'grep' below out of order, well
# after the lines "--- Test 4" etc. are printed. 'wait' prevents this.
grep '.*' $ME | no_op
wait
putln "grep not killed by SIGPIPE, good"

putln '' '--- Test 4'
putln '--- This should produce an error and terminate the program, demonstrating.'
putln "--- that 'harden' can terminate the main program from a subshell."
# Trigger an error in 'grep' by grepping a nonexistent file.
putln "this file has $(grep -c '.*' /dev/null/non/existent/file) lines"

putln "we should never make it to here, BAD"
exit 128
