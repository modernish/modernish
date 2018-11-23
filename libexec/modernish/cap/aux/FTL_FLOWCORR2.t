#! fatal/bug/test/for/moderni/sh

# FTL_FLOWCORR2: trying to launch a nonexistent command from a dot script
# sourced with 'command .' causes program flow corruption. (dash < 0.5.7)
#
# Helper script sourced from bin/modernish to test 'command .' on init.
# dash 0.5.6.1 never executes ':', causing a nonzero exit status.
# Also, triggering the bug makes the shell very likely to hang.

/dev/null/nonexistent 2>/dev/null || :
PATH=$DEFPATH
echo ok
