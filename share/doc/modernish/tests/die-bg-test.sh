#! /usr/bin/env modernish
#! use safe -k
#! use var/arith/ops	# for 'inc'
#! use var/stack/trap	# for 'pushtrap' and DIE pseudosignal

# This test program demonstrates that 'die' can kill the main program
# even from a background subshell.
#
# Conversely, the trap on INT (user presses Ctrl-C) demonstrates how to kill
# the background job from the main shell (which was always possible).

# Demonstrate that modernish has a DIE pseudosignal; its traps will be
# executed when 'die' is called. The pseudosignal cannot be ignored.
trap "putln 'DIE trap invoked'" DIE

putln 'This program will self-destruct in 10 seconds.'
( sleep 10; die 'suicide!' ) &
bgjob=$!

# Without a SIGINT trap, the background process would go on if you press
# Ctrl-C (note: 'pushtrap' does not cause signal to be ignored, unlike
# 'trap', so no 'exit' needed)
pushtrap "die 'Interrupted'" INT

( putln 'Entering infinite loop...'
x=0
forever do
	put "$x "
	inc x
	sleep 1
done ) &

wait

exit 1 "ERROR: We should never get here."
