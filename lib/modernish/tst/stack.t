#! test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# Test the stack for variables and shell options
# (the push and pop commands and related utilities).

TEST title='restore unset status'
	push var
	unset -v var
	push var
	var=foo
	pop var
	not isset -v var
	pop --keepstatus var
ENDT

TEST title='restore unset status (IFS)'
	# IFS is sometimes targeted specifically by shell bugs
	push IFS
	unset -v IFS
	push IFS
	IFS=" "
	pop IFS
	not isset -v IFS
	pop --keepstatus IFS
ENDT

TEST title='restore variable content'
	push --key=save i
	i=0; while let "(i+=1)<=9"; do
		push i
	done
	var=
	while pop i; do
		var=$var$i
	done
	str eq $var 987654321
	pop --key=save --keepstatus i
ENDT

TEST title='push/pop/stackempty with key'
	push --key=save k i var
	for k in kY1 Ky2 k3; do
		i=0; while let "(i+=1)<=5"; do
			push --key=$k i
		done
	done
	pop i && return 1
	output=$(printstack i)
	for k in k3 Ky2 kY1; do
		var=
		stackempty --key=$k i && return 1
		while	pop i && return 1
			pop --key=wrong i && return 1
			pop --key=$k i
		do
			var=$var$i
		done
		str eq $var 54321 || return 1
		stackempty i || return 1
		stackempty --key=$k i || return 1
		stackempty --force i && return 1
	done
	stackempty k && stackempty i && stackempty var || return 1
	not stackempty --force k && not stackempty --force i && not stackempty --force var || return 1
	pop --key=save k i var || return 1
	stackempty k && stackempty i && stackempty var || return 1
	stackempty --force k && stackempty --force i && stackempty --force var || return 1
	str begin $output '--- key: k3
     15: 5
     14: 4
     13: 3
     12: 2
     11: 1
--- key: Ky2
     10: 5
      9: 4
      8: 3
      7: 2
      6: 1
--- key: kY1
      5: 5
      4: 4
      3: 3
      2: 2
      1: 1
--- key: save'
ENDT

TEST title='match option name to letter'
	push --key=save -C
	set -C
	push -o noclobber	# must be the same as 'push -C', so 'pop -C' must work
	set +C
	pop -C || { set -C; return 1; }
	isset -C
	pop --keepstatus --key=save -C
ENDT

TEST title='match "someoption" to "nosomeoption"'
	if not thisshellhas -o noallexport; then
		# 'allexport' is a POSIX option, so 'noallexport' should exist on all
		# shells with a dynamic "no" option name prefix
		skipmsg='no dynamic "no-"'
		return 3
	fi
	push --key=save -o noclobber
	set -C
	push -o clobber
	set +C
	push -o noclobber
	set -o noclobber
	push -C
	output=$(printstack -o noclobber) || return 1
	clearstack -o noclobber || return 1
	stacksize --silent -o clobber
	pop --key=save -C || return 1
	eq REPLY 1 || return 1	# REPLY from stacksize
	str begin $output '      3: 
      2
      1: 
--- key: save'
ENDT

TEST title='clearstack with key'
	push --key=save k i var
	i=0; while let "(i+=1)<=5"; do
		push i
	done
	for k in kY1 Ky2 k3; do
		i=0; while let "(i+=1)<=5"; do
			push --key=$k i
		done
	done
	stacksize --silent i
	eq REPLY 21 || return 1
	var=
	for k in k3 Ky2 kY1; do
		clearstack i && return 1
		clearstack --key=$k i || return 1
		stacksize --silent i
		var=${var:+$var,}$REPLY
	done
	str eq $var 16,11,6 || return 1
	clearstack i
	stacksize --silent i
	eq REPLY 1 || return 1
	pop --key=save k i var || return 1
ENDT
