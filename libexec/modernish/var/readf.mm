#! /module/for/moderni/sh

# Reads an arbitrary file into a variable in format suitable for 'printf'.

# TODO: make someting of this, perhaps based on:
# http://malwaremusings.com/scripts/unhex-awk/


readf() {
	LC_CTYPE=C od -t x1 "$1" \
	| gawk  'BEGIN {
			ORS=""
		}

		{
			for (i=2; i<17; i++) {
				printf ("%c", strtonum("0x" $i));
			}
		}'
}
