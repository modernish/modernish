#! fatal/bug/test/for/moderni/sh

# zsh on Solaris 11.3 has a fatal bug: if a subshell exits due to an error
# in a special builtin or redirection, execution flow is corrupted in such a
# manner that, when end of file is reached without an explicit 'return' or
# 'exit' being encountered, execution of the file does not end but restarts
# at the point exactly after the subshell was exited. The second time
# around, if program specifics allow it, execution ends normally.
#
# For that reason, this fatal bug can only be tested for in a file of its own.
# Thankfully a sourced dot script triggers the bug just as cleanly as a
# standalone script. This helper script is sourced during bin/modernish init.
#
# The bug only manifests if POSIXBUILTINS is active (meaning, it certainly
# will manifest if you're running modernish on zsh under Solaris).

# Execution counter.
_Msh_test=0

# Exit from a subshell due to an error triggers the bug.
(set -o nonexistent_@_option) 2>/dev/null

# With the bug, this will be executed twice so it'll return true.
# Otherwise, it will be executed once and return false.
let "(_Msh_test += 1) > 1"

# End of file: with the bug, it'll now jump back, once, to just after the
# subshell error. The bug only manifests if we let execution end due to end
# of file, so don't "return" explicitly.
#
# One funny thing about this bug is, if we'd "return" explicitly now, the bug
# would "move up" in the calling hierarchy; that is, if the file sourcing this
# file would end execution due to end of file, its execution would resume to
# right after the command that sourced this file. This phenomenon is how I
# initially encountered the bug: with 'modernish --test', it would mysteriously
# try to run the test suite twice. Tracking this bizarre bug down was
# certainly an interesting exercise.
