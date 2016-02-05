# --- Integer arithmetic tests. ---
# if eq $((2+2)) $((5-1)) 4; then echo 'all is right with the world'; fi

_msh_dienint() {
	_msh_n=$1
	shift
	die "$_msh_n: non-integer number in arguments: $@"
}
isint() {
	test $# -ge 1 || _msh_dienarg isint $# 'at least 1'
	printf '%d' "$@" >/dev/null 2>&1
	_msh_k=$1
	shift
	for _msh_v; do
		test $_msh_k -eq $_msh_v || return
	done
}
eq() {
	test $# -ge 2 || _msh_dienarg eq $# 'at least 2'
	printf '%d' "$@" >/dev/null 2>&1 || _msh_dienint eq "$@"
	_msh_k=$1
	shift
	for _msh_v; do
		test $_msh_k -eq $_msh_v || return
	done
}
ne() {
	test $# -ge 2 || _msh_dienarg ne $# 'at least 2'
	printf '%d' "$@" >/dev/null 2>&1 || _msh_dienint ne "$@"
	_msh_k=$1
	shift
	for _msh_v; do
		test $_msh_k -ne $_msh_v || return
	done
}
lt() {
	test $# -ge 2 || _msh_dienarg lt $# 'at least 2'
	printf '%d' "$@" >/dev/null 2>&1 || _msh_dienint lt "$@"
	_msh_k=$1
	shift
	for _msh_v; do
		test $_msh_k -lt $_msh_v || return
	done
}
le() {
	test $# -ge 2 || _msh_dienarg le $# 'at least 2'
	printf '%d' "$@" >/dev/null 2>&1 || _msh_dienint le "$@"
	_msh_k=$1
	shift
	for _msh_v; do
		test $_msh_k -le $_msh_v || return
	done
}
gt() {
	test $# -ge 2 || _msh_dienarg gt $# 'at least 2'
	printf '%d' "$@" >/dev/null 2>&1 || _msh_dienint gt "$@"
	_msh_k=$1
	shift
	for _msh_v; do
		test $_msh_k -gt $_msh_v || return
	done
}
ge() {
	test $# -ge 2 || _msh_dienarg ge $# 'at least 2'
	printf '%d' "$@" >/dev/null 2>&1 || _msh_dienint ge "$@"
	_msh_k=$1
	shift
	for _msh_v; do
		test $_msh_k -ge $_msh_v || return
	done
}
