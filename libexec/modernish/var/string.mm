#! /module/for/moderni/sh

# var/string
# String manipulation functions.
#
# So far, this module has:
#	- sortsbefore, sortsafter: Lexical string comparison. This is provided
#	  because the POSIX shell provides no standard builtin way to do this.
#	- toupper, tolower: Convert case in variables.
#	- trim: Strip whitespace or other characters from the beginning and
#	  end of a variable's value.
#	- replacein: Replace the leading or trailing occurrence or all
#	  occurrences of a string by another string in a variable.
#	- append: Append one or more strings to a variable, separated by
#	  a string of one or more characters, avoiding the hairy problem of
#	  dangling separators.
#	- prepend: Prepend one or more strings to a variable, separated
#	  by a string of one or more characters, avoiding the hairy problem
#	  of dangling separators.
# TODO:
#	- repeatc: Repeat a character or string n times.
#	- splitc: Split a string into individual characters.
#	- leftstr: Get the left n characters of a string.
#	- midstr: Get n characters from position x in a string.
#	- rightstr: Get the right n characters of a string.
#
# --- begin license ---
# Copyright (c) 2019 Martijn Dekker <martijn@inlv.org>, Groningen, Netherlands
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# --- end license ---

# ------------
# ... extra string comparison tests ...
# ------------

use var/string/sortstest

# ------------
# ... string modification operations ...
# ------------

use var/string/touplow
use var/string/trim
use var/string/replacein
use var/string/append
