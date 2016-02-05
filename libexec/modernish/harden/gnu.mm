#! /bin/sh

# Modernish module: harden/gnu
# Harden GNU-specific utilities by catching exit statuses indicating errors.
# See their man or info pages for exit status specifications.

### gzip
# 0 = success, 1 = error, 2 = warning
harden gzip 'eq 1'

