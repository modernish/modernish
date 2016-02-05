#! /bin/sh

# Modernish module: harden/posix/common
# Harden commonly used POSIX utilities by catching exit statuses indicating errors.

### basename
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/basename.html#tag_20_07_14
harden basename 'gt 0'

### cat
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/cat.html#tag_20_13_14
harden cat 'gt 0'

### cd
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/cd.html#tag_20_14_14
harden cd 'gt 0'

### chgrp
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/chgrp.html#tag_20_16_14
harden chgrp 'gt 0'

### chmod
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/chmod.html#tag_20_17_14
harden chmod 'gt 0'

### chown
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/chown.html#tag_20_18_14
harden chown 'gt 0'

### cmp
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/cmp.html#tag_20_20_14
harden cmp 'gt 1'

### comm
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/comm.html#tag_20_21_14
harden comm 'gt 0'

### command
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/command.html#tag_20_22_14
# Hardening functions themselves use 'command', so we can't harden it. There
# would be an infinite loop. Instead, exit status 126 and 127 is already
# caught by the 'gt 0' or 'gt 1' standard for most hardening checks anyway.
#harden commmand 'ge 126'

### cp
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/cp.html#tag_20_24_14
harden compress 'gt 0'

### cut
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/cut.html#tag_20_28_14
harden cut 'gt 0'

### date
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/date.html#tag_20_30_14
harden date 'gt 0'

### dd
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/dd.html#tag_20_31_14
harden dd 'gt 0'

### df
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/df.html#tag_20_33_14
harden df 'gt 0'

### diff
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/diff.html#tag_20_34_14
harden diff 'gt 1'

### dirname
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/dirname.html#tag_20_35_14
harden dirname 'gt 0'

### du
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/du.html#tag_20_36_14
harden du 'gt 0'

### env
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/env.html#tag_20_39_14
# Error status of 'env' conflicts with error status of utility executed by 'env'!
# Distinguishing between the two is not possible, so 'env' cannot be effectively
# hardened. Only exit status 126 and 127 is clearly indicative of an 'env' error.
harden env 'eq 126 || eq 127'

### expr
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/expr.html#tag_20_42_14
harden expr 'gt 1'

### false
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/false.html#tag_20_43_14
# Not hardenable.



# TODO: continue
