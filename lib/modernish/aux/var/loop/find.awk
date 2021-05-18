#! /modernish/helper/script/for/awk -f
#
# This script is used by find.sh and find-ok.sh to write safely shell-quoted
# loop iterations for the find loop (var/loop/find).
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
	ORS = "";
	base = ("_loop_base" in ENVIRON ? ENVIRON["_loop_base"] : "");
	if ("_loop_xargs" in ENVIRON) {
		if (ENVIRON["_loop_xargs"] == "") {
			# Generate a "set --" command to fill the PPs.
			print "set --";
			for (i = 1; i < ARGC; i++) {
				print (" ")(shellquote((base)(ARGV[i])));
			}
			print "\n";
		} else {
			# Generate a ksh93-style array assignment.
			print (ENVIRON["_loop_xargs"])("=(");
			for (i = 1; i < ARGC; i++) {
				print (" ")(shellquote((base)(ARGV[i])));
			}
			print " )\n";
		}
	} else {
		# Generate one assignment iteration per file.
		v = ENVIRON["_loop_V"];
		for (i = 1; i < ARGC; i++) {
			print (v)("=")(shellquote((base)(ARGV[i])))("\n");
		}
	}
	# Interactive mode. Tell main shell to send SIGCONT to stopped find-ok.sh.
	#    Normally, writing an extra line causes an extra loop iteration. To
	# avoid that, make the main shell explicitly read and eval another command
	# before the next iteration. This must be the same read/eval as in the DO
	# alias defined in var/loop.mm.
	if (_loop_SIGCONT) {
		print ("command kill -s CONT ")(_loop_SIGCONT);
		print (" && IFS= read -r _loop_i <&8 && eval \" ${_loop_i}\"\n");
	}
}

# Simple portable string replacement function to use instead of gsub(), which:
# (a) isn't portable for replacing backslashes by double backslashes,
#     see: https://www.gnu.org/software/gawk/manual/html_node/Gory-Details.html
#	   https://github.com/onetrueawk/awk/issues/66
# (b) is wildly buggy with replacing control characters on Solaris /usr/xpg4/bin/awk
function replace(s, old, new,
b, L, ns) {
	if (index(s, old)) {
		L = length(old);
		ns = "";
		while (b = index(s, old)) {
			ns = (ns)(substr(s, 1, b - L))(new);
			s = substr(s, b + L);
		}
		return (ns)(s);
	} else {
		return s;
	}
}

# Double-quote a string, replacing control characters with modernish $CC*.
# This guarantees a one-line, printable quoted string.
function shellquote(s) {
	s = replace(s, "\\", "\\\\");
	s = replace(s, "\"", "\\\"");
	s = replace(s, "$", "\\$");
	s = replace(s, "`", "\\`");
	if (match(s, /[\1\2\3\4\5\6\7\10\11\12\13\14\15\16\17\20\21\22\23\24\25\26\27\30\31\32\33\34\35\36\37\177]/)) {
		s = replace(s, "\1", "${CC01}");
		s = replace(s, "\2", "${CC02}");
		s = replace(s, "\3", "${CC03}");
		s = replace(s, "\4", "${CC04}");
		s = replace(s, "\5", "${CC05}");
		s = replace(s, "\6", "${CC06}");
		s = replace(s, "\7", "${CCa}");
		s = replace(s, "\10", "${CCb}");
		s = replace(s, "\11", "${CCt}");
		s = replace(s, "\12", "${CCn}");
		s = replace(s, "\13", "${CCv}");
		s = replace(s, "\14", "${CCf}");
		s = replace(s, "\15", "${CCr}");
		s = replace(s, "\16", "${CC0E}");
		s = replace(s, "\17", "${CC0F}");
		s = replace(s, "\20", "${CC10}");
		s = replace(s, "\21", "${CC11}");
		s = replace(s, "\22", "${CC12}");
		s = replace(s, "\23", "${CC13}");
		s = replace(s, "\24", "${CC14}");
		s = replace(s, "\25", "${CC15}");
		s = replace(s, "\26", "${CC16}");
		s = replace(s, "\27", "${CC17}");
		s = replace(s, "\30", "${CC18}");
		s = replace(s, "\31", "${CC19}");
		s = replace(s, "\32", "${CC1A}");
		s = replace(s, "\33", "${CCe}");
		s = replace(s, "\34", "${CC1C}");
		s = replace(s, "\35", "${CC1D}");
		s = replace(s, "\36", "${CC1E}");
		s = replace(s, "\37", "${CC1F}");
		s = replace(s, "\177", "${CC7F}");
	}
	return ("\"")(s)("\"");
}
