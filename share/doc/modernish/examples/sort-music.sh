#! /usr/bin/env modernish
#! use safe -k
#! use sys/cmd
#! use var/assign
#! use var/loop
#! use var/string
harden -p cut
harden -e '>1' ffprobe	# ffprobe comes with the ffmpeg package
harden -p -t mkdir
harden -p -t ln
harden -p printf
PATH=/dev/null		# more bug-proof: only allow hardened external commands

# Have a disk or directory with scattered or disorganised music files? This
# script searches a directory for audio/music files, and creates hardlinks or
# symlinks to all files found in a new directory hierarchy, organised by
# artist, album, track number and title, based on the metadata read from the
# files. This way, your files are organised non-destructively without changing
# their original names or locations.
#
# To read the metadata, the script uses 'ffprobe' command from ffmpeg.
#
# By Martijn Dekker <martijn@inlv.org>, February 2019. Public domain.

# ____ configuration ____

# where to search for your music
musicdir=~/Music

# where to store organised links
sorteddir=~/Music/sorted

# ERE describing the filename extensions of files to be processed, in lowercase
extensions='^mp[34]$|^m4a$|^ogg$|^wma$|^flac$|^aiff?$|^wav$'

# set to 'y' to create symlinks instead of hardlinks
symlinks='y'

# ____ initialisation ____

is dir $musicdir || exit 2 "$musicdir doesn't exist"
is dir $sorteddir || mkdir -p $sorteddir

if str eq $symlinks 'y'; then
	ln_opt='-s'
else
	ln_opt=''
	if not is onsamefs $musicdir $sorteddir; then
		exit 2 "$musicdir and $sorteddir are on different file" \
			"systems; hardlinks would be impossible"
	fi
fi

# ____ main program ____

processedfiles=0
totalfiles=0

LOOP find musicfile in $musicdir \
	-path $sorteddir -prune -or -xdev -type f -iterate
DO
	let "totalfiles += 1"

	# Determine if we should process this file.
	extension=${musicfile##*.}
	str eq $extension $musicfile && continue	# no extension
	tolower extension
	str ematch $extension $extensions || continue

	# Initialise tag variables.
	artist=''
	album=''
	title=''
	track=''

	# Read metadata from ffprobe output using process substitution. Lines
	# from ffprobe are in the form "TAG:artist=Artist name here", etc.;
	# remove initial TAG: and treat the rest as variable assignments.
	while read -r tag; do
		assign ${tag#TAG:}
	done < $( % ffprobe -loglevel 16 \
			-show_entries format_tags=artist,album,title,track \
			-of default=noprint_wrappers=1:nokey=0 \
			$musicfile )

	# Make artist, album, title and track number suitable for file names.
	# ...fill in if empty
	str empty $artist && artist='_unknown_artist'
	str empty $album && album='_unknown_album'
	str empty $title && title=${musicfile##*/} && title=${title%.*}
	# ...replace any directory separators (/)
	replacein -a artist '/' '\'
	replacein -a album '/' '\'
	replacein -a title '/' '\'
	# ...remove any leading and trailing whitespace
	trim artist
	trim album
	trim title
	# ...remove any initial 'The ' from artist name(s) and limit length
	artist=${artist#[Tt][Hh][Ee][ _-]}
	let "${#artist} > 32" && artist=$(putln $artist | cut -c 1-29)...
	# ...format track number, if any
	track=${track%%/*}  # remove total number of tracks
	str isint $track && track=$(printf '%02d ' $track) || track=

	# Determine and check the new path.
	newdir=$sorteddir/$artist/$album
	newname=$track$title.${musicfile##*.}
	if not is dir $newdir; then
		mkdir -p $newdir
	elif is present $newdir/$newname; then
		putln "WARNING: skipping duplicate: $newdir/$newname" >&2
		continue
	fi

	# Hardlink or symlink the original to the new path.
	ln $ln_opt $musicfile $newdir/$newname

	let "processedfiles += 1"
DONE

putln "$processedfiles out of $totalfiles files processed"
