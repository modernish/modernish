#! /module/for/moderni/sh

# modernish sys/text/kitten
# 
# kitten is cat without launching any external process.
# Much slower than cat for big files, but much faster for tiny ones.
# Limitation: Text files only. Incompatible with binary files.
# Use cases:
# -	Allows showing here-documents with less overhead.
# -	Faster reading / conkittenenating / copying of small text files.
# Usage: just like cat. '-' is supported. No options are supported.
# 
# nettik is GNU 'tac' without launching any external process.
# Output each file in reverse order, last line first. See kitten().
# This gets slow for files greater than a couple of kB, but then
# again, 'tac' is not available on non-GNU systems so this can
# still be useful.
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

kitten() {
	if let "$#"; then
		_Msh_kittenE=0
		for _Msh_kittenA do
			case ${_Msh_kittenA} in
			( - )	kitten ;;
			( * )	if not is -L present "${_Msh_kittenA}"; then
					print "kitten: ${_Msh_kittenA}: File not found" 1>&2
					_Msh_kittenE=1
					continue
				elif is -L dir "${_Msh_kittenA}"; then
					print "kitten: ${_Msh_kittenA}: Is a directory" 1>&2
					_Msh_kittenE=1
					continue
				fi
				kitten < "${_Msh_kittenA}" ;;
			esac || _Msh_kittenE=1
		done
		eval "unset -v _Msh_kittenA _Msh_kittenE; return ${_Msh_kittenE}"
	fi
	while IFS='' read -r _Msh_kittenL; do
		print "${_Msh_kittenL}"
	done
	# also output any possible last line without final newline
	not empty "${_Msh_kittenL}" && echo -n "${_Msh_kittenL}"
	unset -v _Msh_kittenL
}

nettik() {
	if let "$#"; then
		_Msh_nettikE=0
		for _Msh_nettikA do
			case ${_Msh_nettikA} in
			( - )	nettik ;;
			( * )	if not is -L present "${_Msh_nettikA}"; then
					print "nettik: ${_Msh_nettikA}: File not found" 1>&2
					_Msh_nettikE=1
					continue
				elif is -L dir "${_Msh_nettikA}"; then
					print "nettik: ${_Msh_nettikA}: Is a directory" 1>&2
					_Msh_nettikE=1
					continue
				fi
				nettik < "${_Msh_nettikA}" ;;
			esac || _Msh_nettikE=1
		done
		eval "unset -v _Msh_nettikA _Msh_nettikE; return ${_Msh_nettikE}"
	fi
	_Msh_nettikF=''
	while IFS='' read -r _Msh_nettikL; do
		_Msh_nettikF=${_Msh_nettikL}${CCn}${_Msh_nettikF}
	done
	# (if there is a last line w/o final newline, prepend it without separating newline;
	# this is the behaviour of GNU 'tac')
	echo -n "${_Msh_nettikL}${_Msh_nettikF}"
	unset -v _Msh_nettikL _Msh_nettikF
}

if thisshellhas ROFUNC; then
	readonly -f kitten nettik
fi
