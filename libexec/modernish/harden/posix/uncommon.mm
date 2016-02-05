#! /bin/sh

# Modernish module: harden/posix/uncommon
# Harden uncommonly used POSIX utilities by catching exit statuses indicating errors.

### alias
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/alias.html#tag_20_02_14
harden alias 'gt 0'

### ar
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/ar.html#tag_20_03_14
harden ar 'gt 0'

### asa
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/ar.html#tag_20_04_14
# Does anyone actually have or use this?
#harden asa 'gt 0'

### at
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/at.html#tag_20_05_14
harden at 'gt 0'

### awk
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/awk.html#tag_20_06_14
# "(The exit status can be altered within the program by using an exit expression.)"
# So it needs to be decided on a program-to-program basis whether to harden it,
# and what exit status to check for.
#harden awk 'gt 0'

### batch
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/batch.html#tag_20_08_14
harden batch 'gt 0'

### bc
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/batch.html#tag_20_09_14
# Exit status indicating error is unspecified.
#harden bc

### bg
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/bg.html#tag_20_10_14
# This is only relevant in interactive shells.
#harden bg 'gt 0'

### c99
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/c99.html#tag_20_11_14
# Development.
#harden c99 'gt 0'

### cal
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/cal.html#tag_20_12_14
harden cal 'gt 0'

### cflow
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/cflow.html#tag_20_15_14
# Development. Does this actually exist anyway?
#harden cflow 'gt 0'

### cksum
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/cksum.html#tag_20_19_14
harden cksum 'gt 0'

### compress
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/compress.html#tag_20_23_14
harden compress 'eq 1 || gt 2'

### crontab
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/crontab.html#tag_20_25_14
harden crontab 'gt 0'

### csplit
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/csplit.html#tag_20_26_14
harden csplit 'gt 0'

### ctags
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/ctags.html#tag_20_27_14
harden ctags 'gt 0'

### cxref
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/cxref.html#tag_20_29_14
#harden cxref 'gt 0'

### delta
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/delta.html#tag_20_32_14
#harden delta 'gt 0'

### ed
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/ed.html#tag_20_38_14
harden ed 'gt 0'

### ex
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/ex.html#tag_20_40_14
harden ex 'gt 0'

### expand
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/expand.html#tag_20_41_14
harden expand 'gt 0'


# TODO: continue
