#! /bin/sh

# Modernish module: harden/posix
# Harden POSIX utilities by catching exit statuses indicating errors.
# Use harden/posix to effortlessly gain significant security hardening.
#
# Using this involves a change of programming practice. For instance, you
# have to check whether files exist, etc. *before* using these commands.
# TODO: writeup re advantages of this for security-conscious programming

use posix/common
use posix/uncommon
