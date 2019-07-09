#! /usr/bin/env modernish
#! use safe
#! use sys/cmd/harden
#! use var/arith
#! use var/loop/find

# this script searches a tree in directory PATH_SRC for files with
# extension EXT_SRC and copies their timestamps to the already-existing
# corresponding files with extension EXT_DEST in an identical tree in
# directory EXT_DEST. (customize extensions above.)
#
# i have used this, after converting a bunch of Micro$oft Office documents
# to OpenOffice.org format (with the latter's built-in batch converter), to
# restore the original timestamps in the newly converted copies.
#
# if 'getfacl' and 'setfacl' are available, POSIX ACLs are transferred as well.
#
# by martijn@inlv.demon.nl 12 March 2005 - public domain
# 22 Dec 2015: over a decade later: conversion to modernish, just for the hell of it
# 06,07 Feb 2016: tweaks; inclusion in share/doc/modernish/examples
# 02 Jan 2019: change from using sys/dir/traverse to using var/loop/find

harden touch
harden sed
if command -v getfacl && command -v setfacl; then
	# getfacl/setfacl aren't even standardised, yet get drastically reduced
	# functionality if POSIXLY_CORRECT is set; unset it for these commands.
	harden -u POSIXLY_CORRECT getfacl
	harden -u POSIXLY_CORRECT setfacl
	do_facl=1
else
	unset do_facl
fi >/dev/null

# comment out next line if no debug messages wanted
debug=1

# defaults:
ext_src=.doc
ext_dest=.odt
path_src=.
path_dest=.

showusage() {
	putln	"Usage: $ME [ --ext-src=<ext> ] [ --ext-dest=<ext> ] [ --path-src=<path> ] [ --path-dest=<path> ]" \
		"       $ME [ -es <ext> ] [ -ed <ext> ] [ -ps <path> ] [ -pd <path> ]"
}

# eval params:
while gt $# 0
do
	case $1 in
		( --ext-src=*	) ext_src=${1#--ext-src=}	;;
		( --ext-dest=*	) ext_dest=${1#--ext-dest=}	;;
		( --path-src=*	) path_src=${1#--path-src=}	;;
		( --path-dest=*	) path_dest=${1#--path-dest=}	;;
		( -es		) shift; ext_src=$1		;;
		( -ed		) shift; ext_dest=$1		;;
		( -ps		) shift; path_src=$1		;;
		( -pd		) shift; path_dest=$1		;;
		( *		) exit -u 2			;;
	esac
	shift
done

# report params if debug mode on:
isset debug && for n in ext_src ext_dest path_src path_dest
do
	eval "putln \"$n = \$$n\""
done

# the meat of the matter:

# Here is a typical use of "find" as a new shell loop. Unlike regular 'find'
# usage, this can access your shell variables. It's also completely safe
# even for weird filenames containing whitespace, newlines or other control
# characters (provided you either 'use safe' or quote your variables).
total=0 processed=0
LOOP find F in $path_src
DO
	inc total
	if is reg $F && str end $F $ext_src
	then
		dest=$path_dest${F#"$path_src"}
		dest=${dest%"$ext_src"}$ext_dest
		if is reg $dest; then
			isset debug && putln "Setting timestamp of '$dest' to those of '$F'"
			touch -m -r $F $dest
			if isset do_facl; then
				isset debug && putln "Setting ACLs of '$dest' to those of '$F'"
				getfacl -- $F \
				| sed "s?^# file: ${path_src#/}\(.*\)${ext_src}\$?# file: ${path_dest#/}\F${ext_dest}?" \
				| setfacl --restore=/dev/stdin
			fi
			inc processed
		else
			putln "$ME: '$dest' doesn\'t exist. Cannot set timestamp." 1>&2
		fi
	fi
DONE

putln "$processed of $total files processed"
