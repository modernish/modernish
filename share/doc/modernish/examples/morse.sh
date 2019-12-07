#! /usr/bin/env modernish
#! use safe -k
#! use sys/cmd/harden
#! use var/assign
#! use var/loop
#! use var/string/touplow

# michaeltd	2019-11-29
# M. Dekker	2019-12-03 (modernish port)
# https://en.wikipedia.org/wiki/Morse_code
# International Morse Code
# 1. Length of dot is 1 unit
# 2. Length of dash is 3 units
# 3. The space between parts of the same letter is 1 unit
# 4. The space between letters is 3 units.
# 5. The space between words is 7 units.
################################################################################
# Original bash version:
# http://github.com/michaeltd/dots/blob/master/dot.files/.bashrc.d/.var/morse.sh
################################################################################
# MIT License
#
# Copyright (c) 2016 michaeltd
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
################################################################################

# Most 'sleep' commands accept fractions of seconds, but on Solaris only in the
# current locale, so e.g. French users need 'sleep 0,3'. Disable this: harden
# sleep to use the C locale for numbers (must also unset LC_ALL for that).
harden -p -u LC_ALL LC_NUMERIC=C sleep

# Define a 'beep' command, taking 1 fractional seconds argument.
if command -v play >/dev/null; then
	# Use the 'play' command from SoX: http://sox.sf.net
	harden -f beep play -q -n -c2 synth
else
	# Silence
	alias beep=sleep
fi

morA='.-'    morB='-...'  morC='-.-.'  morD='-..'    morE='.'     morF='..-.'
morG='--.'   morH='....'  morI='..'    morJ='.---'   morK='-.-'
morL='.-..'  morM='--'    morN='-.'    morO='---'    morP='.--.'
morQ='--.-'  morR='.-.'   morS='...'   morT='-'      morU='..-'
morV='...-'  morW='.--'   morX='-..-'  morY='-.--'   morZ='--..'
mor0='-----' mor1='.----' mor2='..---' mor3='...--'  mor4='....-'
mor5='.....' mor6='-....' mor7='--...' mor8='----..' mor9='----.'

let "$# < 1" && exit 1 "Usage: ${ME##*/} arguments..." \
		"${CCn}${ME##*/} is an IMC transmitter." \
		"${CCn}It'll transmit your messages to International Morse Code."

# Main loop.
for argument do
	toupper argument
	LOOP for --slice=1 letter in $argument; DO
		put "$letter: "
		if not str in $ASCIIALNUM $letter; then
			sleep .7
			putln
			continue
		fi
		assign -r code=mor$letter
		LOOP for --slice=1 y in $code; DO
			case $y in
			".") put "dot "; beep .1 ;;
			"-") put "dash "; beep .3 ;;
			esac
			sleep .1
		DONE
		putln
		sleep .3
	DONE
	putln
	sleep .7
done
