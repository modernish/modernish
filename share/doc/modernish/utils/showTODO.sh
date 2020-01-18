#! /usr/bin/env modernish
#! use safe -k
#! use sys/cmd/harden
#! use var/loop

# Script to find and pretty-print all TODOs in modernish code (bin/modernish
# plus modules) or any files specified on the command line

# Check if grep supports --color
thisshellhas BUG_HDOCMASK && umask u+r
grepclr=''
PATH=$DEFPATH command grep --color 'Colour' >/dev/null 2>&1 <<EOF \
	&& grepclr='--color'
Colour
EOF

# Harden and trace grep, with options, as grepTodo()
# Note: uses non-POSIX grep options -B, -A; both BSD and GNU 'grep' have them.
harden -t -p -e '>1' -f grepTodo grep $grepclr -B3 -A3 -n -E '(TODO[?:]|BUG:)'

# Are there zero arguments on the command line? If so, search everything
if let "$# == 0"; then

	# First make sure we're in modernish's base directory
	is present bin/modernish || chdir $MSH_PREFIX

	# Grep (un)installer, all modules & tests, and bin/modernish,
	# while skipping backup files.
	LOOP find --glob --xargs in \
		*install.sh \
		lib/modernish \
		bin/modernish \
		-type f ! -name *~ ! -name *.bak
	DO
		grepTodo "$@"
	DONE
else
	# Grep specified files
	grepTodo "$@"

fi
