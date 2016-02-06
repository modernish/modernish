#! /usr/bin/env modernish
use loop/cfor

cfor 'x=0' 'x<1000000' 'x=x+1'; do
	:
done
echo $x
