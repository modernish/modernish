#! /module/for/moderni/sh
# Bash has the read-only variable $UID, as well as $USER which is not
# read-only. Give them to other shells too, and make both of them read-only.

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

case ${#},${1-} in

( 1,-f )
	# Try to force-set the variables even if they are already set.
	# This won't override read-onlies such as $UID on bash, though.

	if not isset UID || (UID=not_readonly) 2>/dev/null; then
		UID=$(command -p id -u) || die "sys/user/id: 'id -u' failed" || return
		readonly UID
	fi

	if not isset USER || (USER=not_readonly) 2>/dev/null; then
		USER=$(command -p id -un) || die "sys/user/id: 'id -un' failed" || return
		readonly USER
	fi
	;;

( 0, )
	# Default: don't override existing values.

	if not isset UID; then
		UID=$(command -p id -u) || die "sys/user/id: 'id -u' failed" || return
		readonly UID
	elif (UID=not_readonly) 2>/dev/null; then
		readonly UID
	fi

	if not isset USER; then
		USER=$(command -p id -un) || die "sys/user/id: 'id -un' failed" || return
		readonly USER
	elif (USER=not_readonly) 2>/dev/null; then
		readonly USER
	fi
	;;

( * )
	echo "sys/user/id: invalid 'use' option(s): $@" 1>&2
	return 1
	;;
esac
