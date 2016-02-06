#! /usr/bin/env modernish
use loop/sfor

sfor 'x=0' '[ $x -lt 1000000 ]' 'x=$((x+1))'; do
	:
done
echo $x
