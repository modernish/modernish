# awk script belonging to modernish var/mapr.mm
#
# This converts the input to commands for the shell to 'eval', based
# on parameters inherited from the environment.
#
# --- begin license ---
# Copyright (c) 2018 Martijn Dekker <martijn@inlv.org>, Groningen, Netherlands
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

# gsub on Solaris awk needs double escaping of backslashes.
function testsolarisbug(q) {
	q = "a'b'c";
	gsub(/'/, "'\\''", q);
	solarisbug = (q == "a'''b'''c");
	if (!solarisbug && q != "a'\\''b'\\''c") {
		print "die \"mapr: internal error: unknown bug with 'gsub' in awk\"; _Msh_M_NR=RET$?; break";
		exit 0;
	}
}

function round8(num) {
	return (num % 8 == 0) ? num : (num - num % 8 + 8);
}

BEGIN {
	testsolarisbug();
	RS = ENVIRON["_Msh_Mo_d"];

	# Some awk versions need a dummy calculation to convert from string to number.
	opt_s = ENVIRON["_Msh_Mo_s"] + 0;
	opt_n = ENVIRON["_Msh_Mo_n"] + 0;
	opt_c = ENVIRON["_Msh_Mo_c"] + 0;
	opt_m = ENVIRON["_Msh_Mo_m"] + 0;
	arg_max = ENVIRON["_Msh_ARG_MAX"] + 0;

	L_cmd = 0;	# count total length of fixed arguments in command line
	for (i=1; i<ARGC; i++) {
		if (opt_m) {
			L_cmd += length(ARGV[i]) + 1;
		} else {
			# macOS seems to need special argument size aligning to avoid a buffer overflow.
			L_cmd += round8(length(ARGV[i]) + 1) + 8;
		}
	}
	ARGC=1;		# nuke arguments so awk won't take them as input files

	c = 0;		# count number of arguments per command invocation
	L = L_cmd;	# count total argument length per command invocation
	tL = 0;		# count total argument length per batch of commands
	cont = 0;	# flag for continuing with multiple awk invocations
}

NR == 1 {
	NR = ENVIRON["_Msh_M_NR"] + 0;	# number of records: inherit from previous batches

	ORS = " ";			# output space-separated arguments
	print "\"$@\"";			# print fixed command line argument(s)
}

NR <= opt_s {
	next;
}

opt_n && NR > opt_n + opt_s {
	exit 0;
}

# main:
{
	if (opt_m) {
		L += length($0) + 1;
	} else {
		# macOS seems to need special argument size aligning to avoid a buffer overflow.
		L += round8(length($0) + 1) + 8;
	}

	# Check the counters.
	if ((opt_c && c >= opt_c) || (opt_m ? L >= opt_m : L >= arg_max)) {
		# Try not to process much more than 4 megs of arguments per batch.
		if ((tL += L) >= 4194304) {
			cont = 1;
			exit 0;
		}
		print "|| _Msh_mapr_ckE \"$@\" || break\n\"$@\"";
		c = 0;
		L = L_cmd;
	}

	c++;

	# Output the record as a shell-quoted argument.
	if (solarisbug) {
		gsub(/'/, "'\\\\''");
	} else {
		gsub(/'/, "'\\''");
	}
	print ("'")($0)("'");
}

END {
	if (ORS == " ") {
		ORS = "\n";
		print "|| _Msh_mapr_ckE \"$@\" || break";
	}
	if (cont) {
		print ("_Msh_M_NR=")(NR+1);
	} else {
		print "_Msh_M_NR=RET0";
	}
}
