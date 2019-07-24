#! /shell/quirk/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# QRK_OPTABBR: long-form option names can be abbreviated down to a length
# where the abbreviation isn't redundant with other long-form option names.
# Quirk found on: AT&T ksh93; yash.

(
	set +o allexport \
	&& set -o allexpor \
	&& str in "$-" "a" \
	&& set +o noclobber \
	&& set -o noclobbe \
	&& str in "$-" "C"
) 2>/dev/null || return 1
