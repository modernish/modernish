#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_CASECC01: glob patterns as in 'case' cannot match an escaped ^A
# ($CC01) control character. Found on: bash 2.05b
#
# This corner case bug necessitates a workaround in bin/modernish
# initialisation when defining match().
#
# (Later bash versions have a variant of this bug that applies only if the
# escape pattern was passed from a variable. But passing escaped strings to
# 'case' from variables is non-standard behaviour, so we don't test it here.
# However, it's tested in bin/modernish when match() is defined.)

# Use 'eval' to avoid the need to include a literal ^A character here.
eval "case 'ab${CC01}cd' in
\\a\\b\\${CC01}\\c\\d) return 1 ;;
esac"
