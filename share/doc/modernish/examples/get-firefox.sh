#! /bin/sh
. modernish
use safe
use var/setlocal
use loop/select
harden wget
harden cd

# Simple modernish script to get latest Firefox ESR version, Dutch language,
# Linux and Windows versions. By Martijn Dekker <martijn@inlv.org> 2015-16
#
# Things to pay attention to:
# - 'use safe' disables field splitting and globbing, making most variable quoting unnecessary
# - use of modernish functions (eq, contains, exists) instead of that test/[ botch
# - 'not' is a synonym of '!'
# - control character constants, e.g. $CCn (or $CC0A) is a newline
# - local field splitting (for $vlist) and variables using setlocal
# - 'select' as in bash/ksh/zsh is now available even on simple POSIX shells like dash...
# - 'exit' can now pass an error message
# - 'print' is not as in ksh/zsh: instead, it simply prints each argument on a new line

fflang=nl	# the language you want (as appears in download URL)

if eq $# 1; then
	version=$1
else
	# extract available versions(s) from mozilla.org
	version=$(wget -q -O - http://www.mozilla.org/en-US/firefox/organizations/all/ \
		| grep "os=linux64&amp;lang=$fflang" | cut -f2 -d'-' | cut -f1 -d'&')
	empty $version && exit 2 "Can't determine current Firefox-ESR version(s); pass one as an argument"
fi

if contains $version $CCn; then
	# contains newline? found several available versions: let user choose one
	print 'Which version?'
	setlocal --dosplit vlist=$version
		select version in $vlist; do
			not empty $version && break
		done
	endlocal
	empty $version && exit
fi

# get Linux version for your current architecture
arch=${arch:-$(uname -m)}
cd /usr/local/src/essential/mozilla-firefox
f=firefox-$version.tar.bz2
if not exists $f; then
	wget --timestamping \
	"https://download-installer.cdn.mozilla.net/pub/firefox/releases/$version/linux-$arch/$fflang/$f"
else
	print "Already downloaded: $f"
fi

# get Windows version
cd /home/mdekker/win/inst/moz
f="Firefox Setup $version.exe"
if not exists $f; then
	 wget --timestamping \
	"https://download-installer.cdn.mozilla.net/pub/firefox/releases/$version/win32/$fflang/$f"
else
	print "Already downloaded: $f"
fi
