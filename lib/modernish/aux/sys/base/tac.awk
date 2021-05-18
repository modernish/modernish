#! /modernish/helper/script/for/awk -f
#
# awk script belonging to modernish sys/base/tac.mm
#
# This does the actual reversing operation according to the parameters given.
# Depends on aux/ematch.awk to convert a POSIX ERE to an awk RE.
#
# --- begin license ---
# Copyright (c) 2020 Martijn Dekker <martijn@inlv.org>
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
	# To preserve final linefeeds (or lack thereof), set a RS that is unlikely at end of text.
	# ^A a.k.a. \1 should rarely occur in text and never at end: it means "start of heading".
	RS = "\1";
}

NR == 1 {
	text = $0;
}

NR > 1 {
	text = (text)(RS)($0);
}

END {
	$0 = "";					# free memory

	# Split text into fields.
	FS = ENVIRON["_Msh_tac_s"];
	if ("_Msh_tac_r" in ENVIRON) {
		FS = convertere(FS);			# convert POSIX ERE to awk RE (from aux/ematch.awk)
	} else {
		gsub(/[\\.[(*+?{|^$]/, "\\\\&", FS);	# literal FS: escape awk RE characters
	}
	if (length(FS) == 1)
		FS = ("(")(FS)(")");			# force parsing as RE (stops split() stripping whitespace)
	n = split(text, field);

	# Save each input separator.
	p = 1;
	for (i = 1; i < n; i++) {
		p += length(field[i]);			# skip field
		if (match(substr(text, p), FS) != 1)	# match separator, store length in RLENGTH
			exit 13;			# (no match: internal error)
		sep[i] = substr(text, p, RLENGTH);	# save separator
		p += RLENGTH;				# skip separator
	}
	text = "";					# free memory

	# Output in reverse order.
	ORS = "";
	if ("_Msh_tac_b" in ENVIRON) {
		# separator precedes record in both input and output
		for (i = n; i >= 0; i--)
			print (sep[i])(field[i+1]);
	} else if ("_Msh_tac_B" in ENVIRON) {
		# separator follows record in input, precedes record in output
		for (i = n; i > 0; i--)
			print (sep[i])(field[i]);
	} else {
		# separator follows record in both input and output
		for (i = n; i > 0; i--)
			print (field[i])(sep[i]);
	}
}
