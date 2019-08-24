#! /usr/bin/awk -f
#
# Script for 'str ematch' for shells that cannot internally handle POSIX
# extended regular expressions (EREs).
#
# Converts POSIX EREs (with bounds) to traditional awk regular expressions
# (without bounds). On very old awk's without support for POSIX character
# classes in bracket expressions, it translates character classes to ASCII
# equivalents. It also disables awk-specific extensions while doing all that.
#
# This script can also be invoked independently as a command.
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

BEGIN {
	if (ARGC != 3)
		errorout("usage: ematch.awk <string> <ERE>");
	detectclass();
	exit !match(ARGV[1], convertere(ARGV[2]));
}

function errorout(s, ere, i) {
	if (s) printf("str ematch: %s\n", s) | "cat >&2";
	if (ere) printf("%s\n", ere) | "cat >&2";
	if (i) printf(i>1 ? ("%")(i-1)("c^\n") : "^\n", " ") | "cat >&2";
	exit 2;
}

function mylocale() {
	if ("LC_ALL" in ENVIRON && ENVIRON["LC_ALL"] != "")
		return ENVIRON["LC_ALL"];
	else if ("LC_CTYPE" in ENVIRON && ENVIRON["LC_CTYPE"] != "")
		return ENVIRON["LC_CTYPE"];
	else if ("LANG" in ENVIRON && ENVIRON["LANG"] != "")
		return ENVIRON["LANG"];
	else
		return "C";
}

# Detect whether this awk supports character classes properly.
function detectclass() {
	# When a UTF-8 locale is active, onetrueawk (before 2019) only matches the first
	# character class in a bracket expression, even when matching simple ASCII characters.
	# Ref.: http://gnats.netbsd.org/54424
	hasclass = match("1", /[[:alpha:][:digit:]]/);

	# Due to a bug in the macOS C library, onetrueawk and mawk (which don't support UTF-8) yield both false positives
	# and false negatives when matching character classes against high-bit bytes in UTF-8 locales on macOS.
	# Ref.: https://github.com/onetrueawk/awk/issues/45
	if (hasclass && match(mylocale(), /[Uu][Tt][Ff]-?8/))
		hasclass = match("éïÑ", /^[[:alpha:]][[:alpha:]][[:alpha:]]$/);
}

# The terms 'branch', 'piece', 'atom' and 'bound' are used as defined
# in the manual page re_format(7) on BSD/macOS, or regex(7) on Linux.
# OpenBSD has the best version: https://man.openbsd.org/re_format.7

function convertere(ere, par, \
	eere, piece, atom, L, c, i, isave, j, b, m, n, d1, d2, havepunct)
{
	par += 0;  # initialise if not given

	L = length(ere);
	c = substr(ere, 1, 1);
	i = 1;
	while (i <= L) {
		#### Parse just enough ERE grammar to know one atom from the next.
		if (c == "(") {
			# Sub-ERE in parentheses
			atom = ("(")(convertere(substr(ere, ++i), par + 1))(")");
			i += (_Msh_eB_isave - 1);
		} else if (par && c == ")") {
			# End of sub-ERE in parentheses
			_Msh_eB_isave = i;
			return eere;
		} else if (c == "|" || c == "^" || c == "$") {
			# Branch separator, ^/$ anchor, or non-anchor special ^/$
			eere = (eere)(c);
			c = substr(ere, ++i, 1);
			continue;
		} else if (c == "\\" && i < L) {
			# Backslash-escaped character: remove backslash for non-special characters.
			# This disables the C-style backslash escapes that are specific to awk.
			c = substr(ere, ++i, 1);
			if (match(c, /[.[\\()*+?{|^$]/))
				atom = ("\\")(c);
			else
				atom = c;
		} else if (c == "[") {
			# Bracket expression
			havepunct = 0;	# if translating to ASCII, handle [:punct:] specially
			atom = "";
			isave = i;
			i++;
			if (substr(ere, i, 1) == "^") {
				i++;  # negator
				atom = (atom)("^");
			}
			if (substr(ere, i, 1) == "]") {
				i++;  # initial ']' represents itself
				atom = (atom)("]");
			}
			while (i <= L && (c = substr(ere, i, 1)) != "]") {
				if (match(d1 = substr(ere, i, 2), /\[[.=:]/)) {
					# [.collation.], [=equivalence=] or [:character:] class
					d2 = (substr(ere, i+1, 1))("]");
					i += 2;
					isave = i - 1;
					while (i < L && substr(ere, i, 2) != d2)
						i++;
					i++;
					j = substr(ere, isave, i - isave);
					if (!hasclass) {
						# No class/locale support: translate to traditional ASCII. Note that awk supports
						# C-style backslash codes even within bracket expressions, unlike POSIX EREs.
						if (j == ":alnum:" ) {
							j = "A-Za-z0-9";
						} else if (j == ":alpha:") {
							j = "A-Za-z";
						} else if (j == ":blank:") {
							j = " \\t";
						} else if (j == ":cntrl:") {
							j = "\\1-\\37\\177";
						} else if (j == ":digit:") {
							j = "0-9";
						} else if (j == ":graph:") {
							j = "\\41-\\176";
						} else if (j == ":lower:") {
							j = "a-z";
						} else if (j == ":print:") {
							j = "\\40-\\176";
						} else if (j == ":punct:") {
							havepunct++;
							j = "";
						} else if (j == ":space:") {
							# onetrueawk does not support "\v", so use "\13".
							# https://github.com/onetrueawk/awk/pull/44
							j = " \\t\\r\\n\\13\\f";
						} else if (j == ":upper:") {
							j = "A-Z";
						} else if (j == ":xdigit:") {
							j = "A-Fa-f0-9";
						} else if (match(j, /^[=.].*[=.]$/)) {
							# Translate collation and equivalence classes to literal
							# characters in parentheses. TODO: is this a sensible fallback?
							j = ("(")(substr(j, 2, length(j) - 2))(")");
							gsub(/\\/, "\\\\", j);
						} else {
							errorout("invalid character class", ere, isave);
						}
						atom = (atom)(j);
					} else {
						# class/locale support: keep it as is
						atom = (atom)("[")(j)("]");
					}
				} else if (c == "\\") {
					# In POSIX EREs, the backslash is not special at all within a bracket expression, but awk
					# parses C-style backslash escape codes in the entire ERE, including bracket expressions.
					# So to convert a POSIX bracket expression, we have to escape the backslash.
					atom = (atom)("\\\\");
				} else {
					# Other single character in bracket expression.
					atom = (atom)(c);
				}
				i++;
			}
			if (i > L)
				errorout("unterminated bracket expression", ere, isave);
			if (havepunct) {
				# Translate ASCII [:punct:] specially, making sure ']' is the first
				# character, and '-' the last, in the entire bracket expression.
				if (substr(atom, 1, 1) == "]") {
					atom = ("][!\"#$%&'()*+,\\./:;<=>?@^_`{|}~")(substr(atom, 2));
				} else {
					atom = ("][!\"#$%&'()*+,\\./:;<=>?@^_`{|}~")(atom);
				}
				if (substr(atom, length(atom), 1) != "-") {
					atom = (atom)("-");
				}
			}
			atom = ("[")(atom)("]");
		} else if (c == "*" || c == "+" || c == "?") {
			errorout("repetition operator not valid here", ere, i);
		} else {
			# Simple character
			atom = c;
		}

		#### Now that we've got an atom, parse repetitions to get a piece.
		c = substr(ere, ++i, 1);
		if (c == "*" || c == "+" || c == "?") {
			# Traditional repetiton operator.
			piece = (atom)(c);
			c = substr(ere, ++i, 1);
		} else if (c == "{" && match(substr(ere, i+1, 1), /[0123456789]/)) {
			# Interval expression, a.k.a. repetition expression, a.k.a. bound.
			# Expand it in terms of the repetition operators '*', '+' and '?'.
			piece = "";
			isave = i;
			b = 1;		# number of bound params
			m = ""; n = "";	# bound params
			while ( (c = substr(ere, ++i, 1)) != "}" && i <= L ) {
				if (c == ",")
					b++;
				else if (!match(c, /[0123456789]/))
					errorout("bound: bad number", ere, i);
				else if (b == 1)
					m = ( (m)(c) ) + 0; # concatenate, convert to int
				else if (b == 2)
					n = ( (n)(c) ) + 0;
			}
			if (i > L)
				errorout("unterminated bound", ere, isave);
			if (b > 2)
				errorout("bound: too many parameters", ere, isave);
			if (b == 1) {
				# {m}: exactly m occurrences
				for (j = 1; j <= m; j++)
					piece = (piece)(atom);
			} else if (n == "") {
				# {m,}: at least m occurrences
				if (m == 0) {
					piece = (atom)("*");
				} else {
					for (j = 1; j <= m; j++)
						piece = (piece)(atom);
					piece = (piece)("+");
				}
			} else {
				# {m,n}: any number of occurrences between m and n, inclusive
				if (n < m)
					errorout("bad bound: max < min", ere, isave);
				for (j = 1; j <= m; j++)
					piece = (piece)(atom);
				for (; j <= n; j++)
					piece = (piece)(atom)("?");
			}
			c = substr(ere, ++i, 1);
		} else {
			# No repetition.
			piece = atom;
		}
		eere = (eere)(piece);
	}
	# End of ERE.
	if (par)
		errorout("unbalanced parentheses", ere);
	return eere;
}
