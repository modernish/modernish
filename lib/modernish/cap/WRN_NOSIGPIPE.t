#! /shell/warning/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# WRN_NOSIGPIPE: Modernish has detected that the process that launched the
# current program has set SIGPIPE to ignore, and has set $SIGPIPESTATUS
# to the special value 99999.
#
# Depending on how a given command 'foo' is implemented, it is now possible
# that a pipeline such as 'foo | head -n 10' never ends; if 'foo' doesn't
# check for I/O errors, the only way it would ever stop trying to write
# lines is by receiving SIGPIPE as 'head' terminates.

str isint "${SIGPIPESTATUS-}" || return 2
return "$((SIGPIPESTATUS != 99999))"
