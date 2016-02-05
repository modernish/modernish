# ---- String tests. ----
isempty() {
	for _msh_v; do
		test -z "$_msh_v" || return
	done
}
isnotempty() {
	test $# -gt 0 || return
	for _msh_v; do
		test -n "$_msh_v" || return
	done
}
issame() {
	test $# -ge 2 || _msh_dienarg isequal $# 'at least 2'
	_msh_k="$1"
	shift
	for _msh_v; do
		test "$_msh_k" = "$_msh_v" || return
	done
}
isnotsame() {
	test $# -ge 2 || _msh_dienarg isnotequal $# 'at least 2'
	_msh_k="$1"
	shift
	for _msh_v; do
		test "$_msh_k" != "$_msh_v" || return
	done
}
