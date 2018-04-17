#! /shell/bug/test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# BUG_CASECC7F: glob patterns as in 'case' cannot match an escaped ^A
# ($CC7F) control character. Found on: bash 2.05b, 3.0, 3.1
#
# This corner case bug necessitates a workaround in bin/modernish
# initialisation when defining match().

# Use 'eval' to avoid the need to include a literal DEL character here.
eval "case 'ab${CC7F}cd' in
\\a\\b\\${CC7F}\\c\\d) return 1 ;;
esac"
