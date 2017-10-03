#! /usr/bin/env modernish
#!use safe -wBUG_APPENDC
#!use var/string
harden -p sed

# Markdown table of contents generator. Reads a Markdown file and based on
# the headers generates a table of contents in Markdown.
#
# Unfortuantely anchor tags are not standardised in Markdown. The default
# Markdown program does not generate anchor tags at all, making links
# inoperable. Multimarkdown and the Github website do support anchor tags,
# but each use their own style. The Multimarkdown style is the default for
# this program; the Github style is activated using the -g option.

# parse options
unset -v opt_g
while getopts g opt; do
	case $opt in
	( \? )	exit 1 ;;
	( g )	opt_g=1 ;;
	esac
done
shift $((OPTIND-1))

# process options
# default: multimarkdown-style anchor tags
sed_mkanchor='s/[^[:alnum:]]//g'
if isset opt_g; then
	# github-style anchor tags
	sed_mkanchor='s/^/user-content-/; s/[[:space:]]/-/g; s/[^[:alnum:]-]//g'
fi

# parse arguments
case $# in
( 0 )	if is onterminal 0; then
		exec < README.md || exit 1 "Cannot find README.md;" \
			"provide file name argument or redirect standard input"
	fi ;;
( 1 )	exec < $1 || exit 1 "Cannot find $1" ;;
( * )	exit 1 "Max 1 argument accepted" ;;
esac

# begin main program
putln "## Table of contents ##" ""

while read -r line; do

	case $line in
	( '## Table of contents'* )
			continue ;;
	( '######'* )	hdlevel=4 ;;
	( '#####'* )	hdlevel=3 ;;
	( '####'* )	hdlevel=2 ;;
	( '###'* )	hdlevel=1 ;;
	( '##'* )	hdlevel=0 ;;
	( * )		continue ;;
	esac

	trim line \#$WHITESPACE
	
	anchor=$(put $line | sed $sed_mkanchor)
	tolower anchor

	# print ToC entry with Markdown list indentation
	let "numspaces = 2 * hdlevel + 1"
	printf "%${numspaces}s * [%s](#%s)\n" ' ' $line $anchor

done
