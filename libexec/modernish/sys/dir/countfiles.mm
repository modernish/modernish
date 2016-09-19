#! /module/for/moderni/sh

# modernish sys/dir/countfiles
#
# countfiles [ -s ] <directory> [ <globpattern> ... ]:
# Count the number of files in a directory, storing the number in $REPLY
# and (unless -s is given) printing it to standard output.
# If any <globpattern>s are given, only count the files matching them.
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

countfiles() {
	unset -v _Msh_cF_s
	while startswith "${1-}" '-'; do
		case $1 in
		( -s )	_Msh_cF_s=y ;;
		( -- )	shift; break ;;
		( * )	die "countfiles: invalid option: $1" || return ;;
		esac
		shift
	done
	case $# in
	( 0 )	die "countfiles: at least one non-option argument expected" || return ;;
	( 1 )	set -- "$1" '.[!.]*' '..?*' '*' ;;
	esac
	
	if not is -L dir "$1"; then
		die "countfiles: not a directory: $1" || return
	fi

	REPLY=0

	push IFS -f
	IFS=''
	set +f
	_Msh_cF_dir=$1
	shift
	contains "$*" / && { pop IFS -f; die "countfiles: directories in patterns not supported" || return; }
	for _Msh_cF_pat do
		set -- "${_Msh_cF_dir}"/${_Msh_cF_pat}
		if is present "$1"; then
			let REPLY+=$#
		fi
	done
	unset -v _Msh_cF_pat _Msh_cF_dir
	pop IFS -f
	isset _Msh_cF_s && unset -v _Msh_cF_s || print "$REPLY"
}

if thisshellhas ROFUNC; then
	readonly -f countfiles
fi
