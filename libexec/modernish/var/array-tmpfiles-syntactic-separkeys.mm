#!/bin/sh

# modernish module: arrays.mm - Associative arrays.
# internal namespace: _Msh_array_*

# _______ init _________

# Arrays use the filesystem and are stored in a temporary directory.
# (The usage below is compatible with both Linux and BSD 'mktemp'.)
readonly _Msh_array_dir=$(mktemp -d '/tmp/_Msh_array_XXXXXX') 

# Check that mktemp did exactly what we expect: create an empty,
# writable directory with path matching /tmp/_Msh_array_??????
case "$_Msh_array_dir" in
( /tmp/_Msh_array_?????? )
	test -d "$_Msh_array_dir" \
	&& test -w "$_Msh_array_dir" \
	&& test -z "$(ls -A "$_Msh_array_dir/" || die 'arrays.mm init: ls failed')" || return
	;;
( * )
	false
	;;
esac || die 'arrays.mm init: failed to create temp dir' || return

# cleanup on exit
# TODO: make common exit trap for modernish
pushtrap "rm -rf $_Msh_array_dir" EXIT


# _______ module functions ___________

aset() {
	test $# -eq 1 || _Msh_dieArgs aset $# 1 || return
	case "$1" in
	( *'['*']='* ) ;;
	( * ) die "aset: syntax error" || return ;;
	esac
	_Msh_array_a=${1%%\[*}
	_Msh_array_k=${1#*\[}; _Msh_array_k=${_Msh_array_k%%]*}
	_Msh_array_v=${1#*=}
	case "$_Msh_array_a$_Msh_array_k" in
	( [!A-Za-z_]* | *[!A-Za-z0-9_]* )
		die "aset: invalid array or key name" || return ;;
	esac
	if ! test -d "$_Msh_array_dir/$_Msh_array_a"; then
		mkdir "$_Msh_array_dir/$_Msh_array_a" \
		|| die "aset: mkdir failed for array $_Msh_array_a" || return
	fi
	printf '%s\n' "$_Msh_array_v" >| "$_Msh_array_dir/$_Msh_array_a/$_Msh_array_k" \
	|| die "aset: failed to store value in $_Msh_array_a[$_Msh_array_k]" || return
}

# aget: get the value of an array's key, storing it in $VAL.
aget() {
	test $# -eq 1 || _Msh_dieArgs aset $# 1 || return
	case "$1" in
	( *'['*']' ) ;;
	( * ) die "aget: syntax error" || return ;;
	esac
	_Msh_array_a=${1%%\[*}
	_Msh_array_k=${1#*\[}; _Msh_array_k=${_Msh_array_k%]}
	case "$_Msh_array_a$_Msh_array_k" in
	( [!A-Za-z_]* | *[!A-Za-z0-9_]* )
		die "aget: invalid array or key name" || return ;;
	esac

	test -r "$_Msh_array_dir/$_Msh_array_a/$_Msh_array_k" \
	|| { unset VAL; return 0; }

	# the obvious simple way kills performance:
	#VAL=$(cat "$_Msh_array_dir/$1/$2") || die "aget: can't read value $1/$2" || return

	# so instead read line by line without launching any subprocess
	{
		IFS='' read -r VAL \
		&& while IFS='' read -r _Msh_array_line; do
			VAL="$VAL
$_Msh_array_line"
		done
	} < "$_Msh_array_dir/$_Msh_array_a/$_Msh_array_k" \
	|| die "aget: failed to read value of $_Msh_array_a[$_Msh_array_k]" || return

}


# adump: output the values of one or more keys to standard output.
# adump -k: output both keynames and values, separated by '='.
# TODO: write this


# aunset: unset a member of an array, or an entire array.
# Deliberately don't use "rm -rf" and "rm -f" because we should be having
# the proper permissions to do it without forcing. If not, there are bigger
# problems and the script should die.
aunset() {
	test $# -eq 1 || _Msh_dieArgs aset $# 1 || return
	case "$1" in
	( *'['*']' )
		_Msh_array_a=${1%%\[*}
		_Msh_array_k=${1#*\[}; _Msh_array_k=${_Msh_array_k%]}
		case "$_Msh_array_a$_Msh_array_k" in
		( [!A-Za-z_]* | *[!A-Za-z0-9_]* )
			die "aunset: invalid array or key name" || return ;;
		esac
		test -r "$_Msh_array_dir/$_Msh_array_a/$_Msh_array_k" || return 0
		rm "$_Msh_array_dir/$_Msh_array_a/$_Msh_array_k"  || die "aunset: rm failed" || return
		;;
	( * )	case "$1" in
		( [!A-Za-z_]* | *[!A-Za-z0-9_]* )
			die "aunset: invalid array name" || return ;;
		esac
		test -d "$_Msh_array_dir/$1" || return 0
		rm -r "$_Msh_array_dir/$1" || die "aunset: rm -r failed" || return
		;;
	esac
}
