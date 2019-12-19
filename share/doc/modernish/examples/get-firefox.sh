#! /usr/bin/env modernish
#! use safe
#! use sys/cmd/harden
#! use var/local
#! use var/loop/select
harden -t wget
harden -e '>1' grep
harden cut

# Simple modernish script to get latest Firefox ESR version, Dutch language,
# Linux and Windows versions. By Martijn Dekker <martijn@inlv.org> 2015-16
#
# Things to pay attention to:
# - 'use safe' disables field splitting and globbing, making most variable quoting unnecessary
# - use of modernish functions (let, contains, is) instead of that test/[ botch
# - 'not' is a synonym of '!'
# - control character constants, e.g. $CCn (or $CC0A) is a newline
# - local field splitting (for $vlist) and variables using LOCAL
# - 'select' as in bash/ksh/zsh is now available even on simple POSIX shells like dash...
# - 'exit' can now pass an error message

fflang=nl	# the language you want (as appears in download URL)

if let "$# == 1"; then
	version=$1
else
	# extract available versions(s) from mozilla.org
	version=$(wget -q -O - http://www.mozilla.org/en-US/firefox/organizations/all/ \
		| grep "os=linux64&amp;lang=$fflang" | cut -f2 -d'-' | cut -f1 -d'&')
	str empty $version && exit 2 "Can't determine current Firefox-ESR version(s); pass one as an argument"
fi

if str in $version $CCn; then
	# contains newline? found several available versions: let user choose one
	putln 'Which version?'
	LOOP select --split version in $version; DO
		not str empty $version && break
	DONE || exit
fi

# get Linux version for your current architecture
arch=${arch:-$(uname -m)}
chdir /usr/local/src/essential/mozilla-firefox
f=firefox-$version.tar.bz2
if not is present $f; then
	wget --timestamping \
	"https://download-installer.cdn.mozilla.net/pub/firefox/releases/$version/linux-$arch/$fflang/$f"
else
	putln "Already downloaded: $f"
fi

# get Windows version
chdir /home/mdekker/win/inst/moz
f="Firefox Setup $version.exe"
if not is present $f; then
	 wget --timestamping \
	"https://download-installer.cdn.mozilla.net/pub/firefox/releases/$version/win32/$fflang/$f"
else
	putln "Already downloaded: $f"
fi
