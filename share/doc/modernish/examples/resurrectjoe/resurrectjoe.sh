#! /usr/bin/env modernish
#! use safe -k
#! use sys/cmd/harden
#! use var/arith

# Restore files from the DEADJOE file produced when the joe editor is killed.
# Using this utility should be easier than copying them back out by hamd.
#
# --- begin licence ---
# Copyright 2013 Martijn Dekker <martijn@inlv.org>, Groningen, Netherlands.
# The use of this program is unrestricted. Its redistribution, with or
# without modification, is permitted provided that:
# (1) this copyright notice, licence and disclaimer block is kept unchanged;
# (2) any modifications to this program are attributed to their authors.
# ALL AUTHORS HEREBY EXPRESSLY DISCLAIM ANY AND ALL WARRANTY AND LIABILITY.
# --- end licence ---
#
# Version history:
# 1.0.6 (2020-01-18):	Change coding style to match modernish recommendations
# 1.0.5 (2018-03-12):	Remove opts/long support (it was broken on (d)ash)
#			Always show full help as usage
# 1.0.4 (2017-02-20):	Adapted to modernish 0.6dev; use harden()
# 1.0.3 (2015-05-25):	Match filenames without path.
# 1.0.2 (2015-05-16):   Converted to modernish shell dialect.
#			Tweaked glob pattern for compatibility with mksh.
# 1.0.1	(2015-04-29):	Fix bugs in glob pattern handling.
#			Fix ksh-incompatible 'isposint'.
# 1.0	(2015-01-03):	Support older DEADJOE date header format.
# 0.2	(2013-01-26):	First release.

version='1.0.6 (2020-01-18)'
self=${ME##*/}

harden -p printf
harden -p sed
PATH=/dev/null	# disallow non-hardened external commands

# --- UI functions ---

show_version() {
	putln "resurrectjoe version $version"
}

# 'exit -u' automatically calls this function
showusage() {
	putln "\
Usage: $self [OPTION]... [GLOB_PATTERN] >NEWFILE
Recover files by name, number or both from a DEADJOE file
as left by the 'joe' editor whenever it unexpectedly dies.
Options:
  -D FILE    read input from FILE instead of 'DEADJOE' in current dir
               or from standard input if FILE is '-'
  -l         list files matching specified GLOB_PATTERN by number,
               or all files if no pattern was specified
  -n N       recover the N'th file matching specified GLOB_PATTERN,
               or the N'th file listed if no pattern was specified
  -v, -V     show version number
  -h         show this help
  -L         show licence"
}

show_licence() {
	sed -n 's/^# //; /\-\-\- begin licence/,/\-\-\- end licence/p' $ME
}

# --- application functions ---

glob_datehdr=' *[Mm]odified files *in JOE when it aborted on *'

# list files named $1 by number ($1 supports glob patterns)
list_file_numbers() {
	count=0
	while read -r line; do
		case $line in
		( '***'$glob_datehdr )
			putln ${line#'***'$glob_datehdr} ;;
		( '*** File '\'$1\' )
			inc count
			line=${line#"*** File '"}
			line=${line%"'"}
			printf '%6d  %s\n' $count $line ;;
		esac
	done
}

# recover the $2'th file named $1 from deadjoe ($1 supports glob patterns)
recover_file() {
	unset -v flag_success
	count=0 filename='' filedate=''

	# read one line ahead, because the separator is preceded by a newline
	read -r line \
	&& while not isset flag_success && read -r nextline; do
		case $nextline in
		( '***'$glob_datehdr )
			filedate=${nextline#'***'$glob_datehdr} ;;
		( '*** File '\'$1\' | '*** File '\'*/$1\')
			filename=${nextline#"*** File '"}
			filename=${filename%"'"}
			inc count
			if eq count $2; then
				read -r line \
				&& while not isset flag_success && read -r nextline; do
					case $nextline in
					( '***'$glob_datehdr | '*** File '\'*\' )
						flag_success=y ;;
					( * )
						putln $line ;;
					esac
					line=$nextline
				done
				if not isset flag_success; then
					# end of last file in DEADJOE reached
					putln $line
					flag_success=y
				fi
			fi
			;;
		esac
		line=$nextline
	done
	if isset flag_success; then
		putln "Successfully recovered file $filename of $filedate." 1>&2
	elif str eq $1 '*'; then
		exit 1 "file $2 not found;" \
			  "there are only $count files"
	else
		exit 1 "instance $2 of '$1' not found;" \
			  "there are $count matching files"
	fi
}

# --- main ---

# parse options
unset -v opt_filenumber opt_list
opt_deadjoe='DEADJOE'
while getopts 'D:ln:vVhL' opt; do
	case $opt in
	( D )	opt_deadjoe=$OPTARG ;;
	( l )	opt_list=y ;;
	( n )	opt_filenumber=$OPTARG ;;
	( v | V )
		show_version; exit ;;
	( h )	show_version; exit -u ;;
	( L )	show_version; show_licence; exit ;;
	( '?' )	exit -u 2 ;;
	( * )	thisshellhas BUG_GETOPTSMA && str eq $opt ':' && exit -u 2
		exit 3 'internal error' ;;
	esac
done
shift $((OPTIND - 1))

# check options
if eq $# 0 && not isset opt_list && not isset opt_filenumber; then
	exit -u 2 "specify either -l or -n, and/or a filename"
fi
if gt $# 1; then
	exit -u 1 "can't specify more than 1 filename or glob pattern at a time"
fi
if isset opt_list && isset opt_filenumber; then
	exit 2 "can't use both -l and -n at once"
fi
if isset opt_filenumber; then
	str isint $opt_filenumber && gt opt_filenumber 0 || exit 2 "invalid file number: '$opt_filenumber'"
else
	opt_filenumber=1
fi
if not str empty $opt_deadjoe && not str eq $opt_deadjoe '-'; then
	is present $opt_deadjoe || exit 1 "$opt_deadjoe: file not found"
	is -L reg $opt_deadjoe || exit 1 "$opt_deadjoe: not a regular file"
	can read $opt_deadjoe || exit 1 "$opt_deadjoe: cannot read from file"
	exec <$opt_deadjoe || exit
fi

# do the job
if isset opt_list; then
	list_file_numbers ${1:-*}
else
	recover_file ${1:-*} $opt_filenumber
fi
