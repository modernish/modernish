#! /usr/bin/env modernish

let x=0
while test $((x=x+1)) -lt 1000000; do
	:
done
echo $x
