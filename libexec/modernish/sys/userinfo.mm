#! /module/for/moderni/sh
# Get a user's login shell using one of several methods, depending on what
# the system supports.
# Usage:
#	loginshell [ <username> ]
# <username> defaults to the current user.
# On success, prints the specified user's login shell to standard output.
# On error, exits with status 2. A system-specific utility may print its own error message.
# If this system has no known way to get the login shell, exits with status 3.
#
# --- begin license ---
# Copyright (c) 2016 Martijn Dekker <martijn@inlv.org>, Groningen, Netherlands
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
# --- end license ---

# ...GNU, *BSD, Solaris
unset -f getent finger perl 2>|/dev/null	# zsh defines a broken getent function by default
if command -v getent; then
	# Globbing applies to the result of an unquoted command substitution,
	# and passwd fields often contain a '*', so turn off globbing.
	loginshell() {
		le "$#" 1 || die "loginshell: incorrect number of arguments (was $#, must be 0 or 1)" || return
		push -f IFS
		set -f
		IFS=:
		set -- "${1-$USER}" $(getent passwd "${1-$USER}") \
		&& eq "$#" 8 \
		&& identic "$2" "$1" \
		&& can exec "$8" \
		&& REPLY=$8 \
		&& print "$8" \
		|| { REPLY=''; pop -f IFS; return 2; }
		pop -f IFS
	}
# ...Mac OS X
elif can exec /usr/bin/dscl && is dir /System/Library/DirectoryServices; then
	loginshell() {
		le "$#" 1 || die "loginshell: incorrect number of arguments (was $#, must be 0 or 1)" || return
		push -f IFS
		set -f
		IFS=$WHITESPACE
		set -- $(/usr/bin/dscl . -read "/Users/${1-$USER}" UserShell) \
		&& eq "$#" 2 \
		&& identic "$1" 'UserShell:' \
		&& can exec "$2" \
		&& REPLY=$2 \
		&& print "$2" \
		|| { REPLY=''; pop -f IFS; return 2; }
		pop -f IFS
	}
# ...finger
elif command -v finger; then
	loginshell() {
		le "$#" 1 || die "loginshell: incorrect number of arguments (was $#, must be 0 or 1)" || return
		set -- "$( export LC_ALL=C
			{ finger -m "${1-$USER}" || die "loginshell: 'finger' failed" || return; } \
			| awk 'BEGIN { verified = false; }
			{
				if ( $1 == "Login:" && $2 == "${1-$USER}" )
					verified = true;
				if ( $3 == "Shell:" && verified == true ) {
					print $4;
					exit;
				}
			}' || die "loginshell: 'awk' failed" || return)"
		if not empty "$1" && can exec "$1"; then
			REPLY=$1
			print "$1"
		else
			REPLY=''
			return 2
		fi
	}
# ...Perl
elif command -v perl; then
	loginshell() {
		le "$#" 1 || die "loginshell: incorrect number of arguments (was $#, must be 0 or 1)" || return
                set -- "$(perl -e "print +(getpwnam \"${1-$USER}\")[8], \"\\n\"")"
		if not empty "$1" && can exec "$1"; then
			REPLY=$1
			print "$1"
		else
			REPLY=''
			return 2
		fi
	}
# ...we don't have a way
else
	loginshell() {
		le "$#" 1 || die "loginshell: incorrect number of arguments (was $#, must be 0 or 1)" || return
		REPLY=''
		return 3
	}
fi >|/dev/null 2>&1
