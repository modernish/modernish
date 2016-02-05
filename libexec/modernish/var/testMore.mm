#!/bin/sh

# Check if values matches a glob pattern.
matchM() {
	[ $# -ge 2 ] || _msh_dieArgs match $# 'at least 2'
	_msh_k="$1"
	shift
	for _msh_v; do case "$_msh_v" in
	( $_msh_k ) ;;
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
	[ $# -ge 1 ] || _msh_dieArgs isint $# 'at least 1'
	printf '%d' "$@" >/dev/null 2>&1
}
eqM() {
	[ $# -ge 2 ] || _msh_dieArgs eq $# 'at least 2'
	printf '%d' "$@" >/dev/null 2>&1 || _msh_dieNonInt eq "$@"
	_msh_k="$1"
	shift
	for _msh_v; do
		[ $_msh_k -eq $_msh_v ] || return
	done
}
neM() {
	[ $# -ge 2 ] || _msh_dieArgs ne $# 'at least 2'
	printf '%d' "$@" >/dev/null 2>&1 || _msh_dieNonInt ne "$@"
	_msh_k="$1"
	shift
	for _msh_v; do
		[ $_msh_k -ne $_msh_v ] || return
	done
}
ltM() {
	[ $# -ge 2 ] || _msh_dieArgs lt $# 'at least 2'
	printf '%d' "$@" >/dev/null 2>&1 || _msh_dieNonInt lt "$@"
	_msh_k="$1"
	shift
	for _msh_v; do
		[ $_msh_k -lt $_msh_v ] || return
	done
}
leM() {
	[ $# -ge 2 ] || _msh_dieArgs le $# 'at least 2'
	printf '%d' "$@" >/dev/null 2>&1 || _msh_dieNonInt le "$@"
	_msh_k="$1"
	shift
	for _msh_v; do
		[ $_msh_k -le $_msh_v ] || return
	done
}
gtM() {
	[ $# -ge 2 ] || _msh_dieArgs gt $# 'at least 2'
	printf '%d' "$@" >/dev/null 2>&1 || _msh_dieNonInt gt "$@"
	_msh_k="$1"
	shift
	for _msh_v; do
		[ $_msh_k -gt $_msh_v ] || return
	done
}
geM() {
	[ $# -ge 2 ] || _msh_dieArgs ge $# 'at least 2'
	printf '%d' "$@" >/dev/null 2>&1 || _msh_dieNonInt ge "$@"
	_msh_k="$1"
	shift
	for _msh_v; do
		[ $_msh_k -ge $_msh_v ] || return
	done
}


# --- File type tests. ---
# Note: These do *not* resolve symlinks unless the L variant is used.
# This is to promote security and discourage allowing symlink attacks.

# symlink
f_issymM() {
	[ $# -ge 1 ] || _msh_dieArgs f_issym $# 'at least 1'
	for _msh_v; do
		[ -L "$_msh_v" ] || return
	done
}

# block special
f_isblkM() {
	[ $# -ge 1 ] || _msh_dieArgs f_isblk $# 'at least 1'
	for _msh_v; do
		[ ! -L "$_msh_v" ] && [ -b "$_msh_v" ] || return
	done
}
f_isblkLM() {
	[ $# -ge 1 ] || _msh_dieArgs f_isblk_L $# 'at least 1'
	for _msh_v; do
		[ -b "$_msh_v" ] || return
	done
}

# character special
f_ischrM() {
	[ $# -ge 1 ] || _msh_dieArgs f_ischr $# 'at least 1'
	for _msh_v; do
		[ ! -L "$_msh_v" ] && [ -c "$_msh_v" ] || return
	done
}
f_ischrLM() {
	[ $# -ge 1 ] || _msh_dieArgs f_ischr_L $# 'at least 1'
	for _msh_v; do
		[ -c "$_msh_v" ] || return
	done
}

# directory
f_isdirM() {
	[ $# -ge 1 ] || _msh_dieArgs f_isdir $# 'at least 1'
	for _msh_v; do
		[ ! -L "$_msh_v" ] && [ -d "$_msh_v" ] || return
	done
}
f_isdirLM() {
	[ $# -ge 1 ] || _msh_dieArgs f_isdir_L $# 'at least 1'
	for _msh_v; do
		[ -d "$_msh_v" ] || return
	done
}

# regular file
f_isregM() {
	[ $# -ge 1 ] || _msh_dieArgs f_isreg $# 'at least 1'
	for _msh_v; do
		[ ! -L "$_msh_v" ] && [ -f "$_msh_v" ] || return
	done
}
f_isregLM() {
	[ $# -ge 1 ] || _msh_dieArgs f_isreg_L $# 'at least 1'
	for _msh_v; do
		[ -f "$_msh_v" ] || return
	done
}

# FIFO (named pipe)
f_isfifoM() {
	[ $# -ge 1 ] || _msh_dieArgs f_isfifo $# 'at least 1'
	for _msh_v; do
		[ ! -L "$_msh_v" ] && [ -p "$_msh_v" ] || return
	done
}
f_isfifoLM() {
	[ $# -ge 1 ] || _msh_dieArgs f_isfifo_L $# 'at least 1'
	for _msh_v; do
		[ -p "$_msh_v" ] || return
	done
}

# socket
f_issockM() {
	[ $# -ge 1 ] || _msh_dieArgs f_issock $# 'at least 1'
	for _msh_v; do
		[ ! -L "$_msh_v" ] && [ -S "$_msh_v" ] || return
	done
}
f_issockLM() {
	[ $# -ge 1 ] || _msh_dieArgs f_issock_L $# 'at least 1'
	for _msh_v; do
		[ -S "$_msh_v" ] || return
	done
}
