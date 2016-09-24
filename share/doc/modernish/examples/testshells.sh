#! /usr/bin/env modernish
use safe -w BUG_UPP -w BUG_APPENDC
use sys/text/rev -wBUG_MULTIBYTE	# for systems without 'rev'
harden grep '> 1'
harden sort
harden printf

unexport POSIXLY_CORRECT

# testshells: run a script on all known Bourne-ish shells (grepping from /etc/shells).

let $# || exit 2 "Specify one script to test, with optional arguments."
is -L reg $1 || exit 2 "Not found: $1"
can read $1 || exit 2 "No read permission: $1"
script=$1
shift

isset COLUMNS || COLUMNS=$(tput cols) || COLUMNS=80

grep -E '^/[a-z/]+/[a-z]*sh[0-9]*$' /etc/shells \
| grep -vE '(csh|/esh|/psh|/fish|/r[a-z])' \
| rev | sort | rev \
| while read -r shell; do
	can exec $shell || continue
	printf '\033[1;34m%24s: \033[0m' $shell
	$shell $script "$@"
	printf '\r\033[%dC\033[1;%dm[%3d]\033[0m\n' $((COLUMNS-5)) $(($?>0?31:32)) $?
done
