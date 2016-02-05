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
# Hardening functionings themselves use 'command', so we can't harden it. There
# would be an infinite loop. Instead, exit status 126 and 127 is already
# caught by the 'gt 0' or 'gt 1' standard for most hardening checks anyway.
#harden commmand 'ge 126'

### cp
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/cp.html#tag_20_24_14
harden compress 'gt 0'

# TODO: continue
