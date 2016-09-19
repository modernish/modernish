#! /module/for/moderni/sh

# modernish sys/base
# This module provides consistent versions of certain essential, but
# non-standard utilities. They provide different command line syntaxes on
# different systems or may not be available on all systems. Since POSIX
# hasn't standardised these, this module provides a consistent version of
# these utilities to modernish scripts on all platforms.
#
# So far, this module has:
#	- readlink
#	- which
#	- mktemp
#	- yes
#
# TODO:
#	- seq
#	- option like GNU --reference for chown/chmod
#	- column
#	- unified interface to BSD and Linux 'stat'
#	- ...
#
# --- begin license ---
# Copyright (c) 2016 Martijn Dekker <martijn@inlv.org>, Groningen, Netherlands
# 
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
# 
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# --- end license ---

use sys/base/readlink
use sys/base/which
use sys/base/mktemp
use sys/base/yes
