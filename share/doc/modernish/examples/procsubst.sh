#! /usr/bin/env modernish
#! use safe
#! use sys/cmd/procsubst
#
# Here are some quick and dirty demonstrations of the use of modernish's
# portable implementation of process substitution. See README.md for info.
#
# See dice.sh for another nice usage example of portable process substitution.
# See the file LICENSE in the modernish main or doc directory for the license.

# This script only uses standard commands, so let's ensure known-good ones.
PATH=$DEFPATH

# -----------------
# --- Example 1 ---
# -----------------
putln "We can automagically prefix & colourise standard error!"
red=$(tput setaf 1)
hilite=$(tput smso)
reset=$(tput sgr0)
# Define a function that will act like a filter, reading standard input,
# transforming it, and copying the transformed lines to standard error.
# Then use output process substitution to send all of stderr through it.
# Note:
# 1. The use of 'exec' makes this situation permanent for the script run. The
#    redirection (everything except the 'exec') could also be attached to any
#    block (even a function definition!) to make the effect local to that.
# 2. As Colourise() runs in the background and takes a little time, things
#    written to standard error may occasionally appear out of order.
Colourise() {
	while read -r line; do
		putln "${hilite}ERR${reset} ${red}${line}${reset}"
	done >&2
}
exec 2> $( % -o Colourise )
putln "This is written to standard error" >&2
putln "This is written to standard output"
ls /nonexistent/file/for/demonstrating/stderr/colourisation

# -----------------
# --- Example 2 ---
# -----------------
putln "====" "We can diff the output of two commands!"
putln "Here are all your hidden (.*) files:"
diff $(% ls) $(% ls -a)

# -----------------
# --- Example 3 ---
# -----------------
putln "====" "We can 'read' command output!"
IFS=' ' read -r user group size args < $(% ps -o user= -o group= -o vsz= -o args= -p $$)
putln	"My command: $args" \
	"My vsize  : $size" \
	"My user   : $user (group: $group)"

# -----------------
# --- Example 4 ---
# -----------------
putln "===="

putln "We can Multiply and Transform text On The Fly!" \
  | tee	$(% -o tr [:upper:] [:lower:]) \
	$(% -o tr [:lower:] [:upper:]) \
	$(% -o sed "s/ /_/g") \
	$(% -o tr a-zA-Z n-za-mN-ZA-M)	# rot13 :)

# Colourised stderr also shows clearly now that '% -o' writes to standard error
# by default. This is different from native process substitution on ksh, bash
# and zsh, but unfortunately it cannot be avoided: the command substitution
# subsumes standard output. It should be mostly fine but sometimes it's a pain,
# like if you're trying to redirect the script's output.
#
# A workaround is possible. It involves two steps:
#
# 1. Enclose the whole thing in a { block; }, to which you append a redirection
#    that saves a copy of stdout (1) in another file descriptor, like 3: 3>&1
#
# 2. Add a 1>&3 redirection to 'tr' to make it write to 3, which is our stdout.
#    This works because our saved FD is inherited by the background process.
#    However, '%' does not support that -- it only takes a simple command, so
#    redirections would not work. But you can make any combination of complex
#    command(s) into a simple command. The sane way would be to use a shell
#    function, like we did with Colourise() above -- but there is also a quick
#    and dirty way: wrap it in an 'eval'. BE SURE TO QUOTE THE ENTIRE COMPLEX
#    COMMAND WITH **SINGLE** QUOTES if you go that unorthodox route -- it's the
#    only way to avoid premature expansion and its related vulnerabilities.
#    As long as you do that, it may still be dirty but it's actually safe.
#    I promise I won't tell anyone. ;)
#
#    Example of the quick and dirty method:
#
#    {
#       putln "We can Duplicate and Transform text On The Fly!" \
#         | tee $(% -o eval 'tr [:upper:] [:lower:] 1>&3') \
#               $(% -o eval 'tr [:lower:] [:upper:] 1>&3') \
#               $(% -o eval 'sed "s/ /_/g" 1>&3') \
#               $(% -o eval 'tr a-zA-Z n-za-mN-ZA-M 1>&3') # rot13 :)
#    } 3>&1
#
# -----------------
# The 'tr' commands above run simultaneously in the background.
# This means two things:
# 1. Their output (which is written to standard error) may appear in any order.
# 2. This main script will finish before the 'tr' invocations do.
# So sleep a little to avoid overwriting your command prompt.
sleep 1
