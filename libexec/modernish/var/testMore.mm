#!/bin/sh

# Check if values matches a glob pattern.
matchM() {
	[ $# -ge 2 ] || _Msh_dieArgs match $# 'at least 2'
	_Msh_k="$1"
	shift
	for _Msh_v; do case "$_Msh_v" in
	( $_Msh_k ) ;;
	( * ) return 1 ;;
	esac; done
}

# --- Integer arithmetic tests taking More than 2 arguments. ---
#
# if eqM $((2+2)) $((5-1)) 4; then echo 'all is right with the world'; fi
#
# Using these instead of regular test/arith functions defeats the security
# hardening of checking for an exact number of arguments. So, when using
# these, remember the security implications of variables expanding into
# multiple arguments -- both in code calling these functions directly, and
# in code leading up to these function calls. Double-check that you have
# double-quoted all your variable references!

isintM() {
	[ $# -ge 1 ] || _Msh_dieArgs isint $# 'at least 1'
	printf '%d' "$@" >| /dev/null 2>&1
}
eqM() {
	[ $# -ge 2 ] || _Msh_dieArgs eq $# 'at least 2'
	printf '%d' "$@" >| /dev/null 2>&1 || _Msh_dieNonInt eq "$@"
	_Msh_k="$1"
	shift
	for _Msh_v; do
		[ $_Msh_k -eq $_Msh_v ] || return
	done
}
neM() {
	[ $# -ge 2 ] || _Msh_dieArgs ne $# 'at least 2'
	printf '%d' "$@" >| /dev/null 2>&1 || _Msh_dieNonInt ne "$@"
	_Msh_k="$1"
	shift
	for _Msh_v; do
		[ $_Msh_k -ne $_Msh_v ] || return
	done
}
ltM() {
	[ $# -ge 2 ] || _Msh_dieArgs lt $# 'at least 2'
	printf '%d' "$@" >| /dev/null 2>&1 || _Msh_dieNonInt lt "$@"
	_Msh_k="$1"
	shift
	for _Msh_v; do
		[ $_Msh_k -lt $_Msh_v ] || return
	done
}
leM() {
	[ $# -ge 2 ] || _Msh_dieArgs le $# 'at least 2'
	printf '%d' "$@" >| /dev/null 2>&1 || _Msh_dieNonInt le "$@"
	_Msh_k="$1"
	shift
	for _Msh_v; do
		[ $_Msh_k -le $_Msh_v ] || return
	done
}
gtM() {
	[ $# -ge 2 ] || _Msh_dieArgs gt $# 'at least 2'
	printf '%d' "$@" >| /dev/null 2>&1 || _Msh_dieNonInt gt "$@"
	_Msh_k="$1"
	shift
	for _Msh_v; do
		[ $_Msh_k -gt $_Msh_v ] || return
	done
}
geM() {
	[ $# -ge 2 ] || _Msh_dieArgs ge $# 'at least 2'
	printf '%d' "$@" >| /dev/null 2>&1 || _Msh_dieNonInt ge "$@"
	_Msh_k="$1"
	shift
	for _Msh_v; do
		[ $_Msh_k -ge $_Msh_v ] || return
	done
}


# --- File type tests. ---
# Note: These do *not* resolve symlinks unless the L variant is used.
# This is to promote security and discourage allowing symlink attacks.

# symlink
f_issymM() {
	[ $# -ge 1 ] || _Msh_dieArgs f_issym $# 'at least 1'
	for _Msh_v; do
		[ -L "$_Msh_v" ] || return
	done
}

# block special
f_isblkM() {
	[ $# -ge 1 ] || _Msh_dieArgs f_isblk $# 'at least 1'
	for _Msh_v; do
		[ ! -L "$_Msh_v" ] && [ -b "$_Msh_v" ] || return
	done
}
f_isblkLM() {
	[ $# -ge 1 ] || _Msh_dieArgs f_isblk_L $# 'at least 1'
	for _Msh_v; do
		[ -b "$_Msh_v" ] || return
	done
}

# character special
f_ischrM() {
	[ $# -ge 1 ] || _Msh_dieArgs f_ischr $# 'at least 1'
	for _Msh_v; do
		[ ! -L "$_Msh_v" ] && [ -c "$_Msh_v" ] || return
	done
}
f_ischrLM() {
	[ $# -ge 1 ] || _Msh_dieArgs f_ischr_L $# 'at least 1'
	for _Msh_v; do
		[ -c "$_Msh_v" ] || return
	done
}

# directory
f_isdirM() {
	[ $# -ge 1 ] || _Msh_dieArgs f_isdir $# 'at least 1'
	for _Msh_v; do
		[ ! -L "$_Msh_v" ] && [ -d "$_Msh_v" ] || return
	done
}
f_isdirLM() {
	[ $# -ge 1 ] || _Msh_dieArgs f_isdir_L $# 'at least 1'
	for _Msh_v; do
		[ -d "$_Msh_v" ] || return
	done
}

# regular file
f_isregM() {
	[ $# -ge 1 ] || _Msh_dieArgs f_isreg $# 'at least 1'
	for _Msh_v; do
		[ ! -L "$_Msh_v" ] && [ -f "$_Msh_v" ] || return
	done
}
f_isregLM() {
	[ $# -ge 1 ] || _Msh_dieArgs f_isreg_L $# 'at least 1'
	for _Msh_v; do
		[ -f "$_Msh_v" ] || return
	done
}

# FIFO (named pipe)
f_isfifoM() {
	[ $# -ge 1 ] || _Msh_dieArgs f_isfifo $# 'at least 1'
	for _Msh_v; do
		[ ! -L "$_Msh_v" ] && [ -p "$_Msh_v" ] || return
	done
}
f_isfifoLM() {
	[ $# -ge 1 ] || _Msh_dieArgs f_isfifo_L $# 'at least 1'
	for _Msh_v; do
		[ -p "$_Msh_v" ] || return
	done
}

# socket
f_issockM() {
	[ $# -ge 1 ] || _Msh_dieArgs f_issock $# 'at least 1'
	for _Msh_v; do
		[ ! -L "$_Msh_v" ] && [ -S "$_Msh_v" ] || return
	done
}
f_issockLM() {
	[ $# -ge 1 ] || _Msh_dieArgs f_issock_L $# 'at least 1'
	for _Msh_v; do
		[ -S "$_Msh_v" ] || return
	done
}
