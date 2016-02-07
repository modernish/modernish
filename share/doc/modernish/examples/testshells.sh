#! /usr/bin/env modernish
use safe
harden grep 'gt 1'
harden sort
harden rev
harden printf

# testshells: run a script on all known Bourne-ish shells (grepping from /etc/shells).

ge $# 1 || exit 2 "Specify one script to test, with optional arguments."
isreg -L $1 || exit 2 "Not found: $1"
canread $1 || exit 2 "No read permission: $1"
script=$1
shift

isset COLUMNS || COLUMNS=$(tput cols) || COLUMNS=80

grep -E '^/[a-z]+*/.*sh[0-9]*$' /etc/shells \
| grep -vE '(csh$|/fish$|/r[a-z]+*)$' \
| rev | sort | rev \
| while read -r shell; do
	canexec $shell || continue
	printf '\033[1;34m%24s: \033[0m' $shell
	$shell $script "$@"
	printf '\r\033[%dC\033[1;%dm[%3d]\033[0m\n' $((COLUMNS-5)) $(($?>0?31:32)) $?
done
