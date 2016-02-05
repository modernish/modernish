#!/bin/sh

# modernish module: arrays.mm - Associative arrays.
# internal namespace: _msh_array_*

# _______ init _________

# Arrays use the filesystem and are stored in a temporary directory.
# (The usage below is compatible with both Linux and BSD 'mktemp'.)
readonly _msh_array_dir=$(mktemp -d '/tmp/_msh_array_XXXXXX') 

# Check that mktemp did exactly what we expect: create an empty,
# writable directory with path matching /tmp/_msh_array_??????
case "$_msh_array_dir" in
( /tmp/_msh_array_?????? )
	test -d "$_msh_array_dir" \
	&& test -w "$_msh_array_dir" \
	&& test -z "$(ls -A "$_msh_array_dir/" || die 'arrays.mm init: ls failed')"
	;;
( * )
	false
	;;
esac || die 'arrays.mm init: failed to create temp dir'

# cleanup on exit
# TODO: make common exit trap for modernish
trap "rm -rf $_msh_array_dir" EXIT


# _______ module functions ___________

aset() {
	test $# -eq 1 || _msh_dieArgs aset $# 1
	case "$1" in
	( *'['*']='* ) ;;
	( * ) die "aset: syntax error" ;;
	esac
	_msh_array_a=${1%%\[*}
	_msh_array_k=${1#*\[}; _msh_array_k=${_msh_array_k%%]*}
	_msh_array_v=${1#*=}
	case "$_msh_array_a$_msh_array_k" in
	( [!A-Za-z_]* | *[!A-Za-z0-9_]* )
		die "aset: invalid array or key name" ;;
	esac
	if ! test -d "$_msh_array_dir/$_msh_array_a"; then
		mkdir "$_msh_array_dir/$_msh_array_a" \
		|| die "aset: mkdir failed for array $_msh_array_a"
	fi
	printf '%s\n' "$_msh_array_v" >| "$_msh_array_dir/$_msh_array_a/$_msh_array_k" \
	|| die "aset: failed to store value in $_msh_array_a[$_msh_array_k]"
}

# aget: get the value of an array's key, storing it in $VAL.
aget() {
	test $# -eq 1 || _msh_dieArgs aset $# 1
	case "$1" in
	( *'['*']' ) ;;
	( * ) die "aget: syntax error" ;;
	esac
	_msh_array_a=${1%%\[*}
	_msh_array_k=${1#*\[}; _msh_array_k=${_msh_array_k%]}
	case "$_msh_array_a$_msh_array_k" in
	( [!A-Za-z_]* | *[!A-Za-z0-9_]* )
		die "aget: invalid array or key name" ;;
	esac

	test -r "$_msh_array_dir/$_msh_array_a/$_msh_array_k" \
	|| { unset VAL; return 0; }

	# the obvious simple way kills performance:
	#VAL=$(cat "$_msh_array_dir/$1/$2") || die "aget: can't read value $1/$2"

	# so instead read line by line without launching any subprocess
	{
		IFS='' read -r VAL \
		&& while IFS='' read -r _msh_array_line; do
			VAL="$VAL
$_msh_array_line"
		done
	} < "$_msh_array_dir/$_msh_array_a/$_msh_array_k" \
	|| die "aget: failed to read value of $_msh_array_a[$_msh_array_k]"

}


# adump: output the values of one or more keys to standard output.
# adump -k: output both keynames and values, separated by '='.
# TODO: write this


# aunset: unset a member of an array, or an entire array.
# Deliberately don't use "rm -rf" and "rm -f" because we should be having
# the proper permissions to do it without forcing. If not, there are bigger
# problems and the script should die.
aunset() {
	test $# -eq 1 || _msh_dieArgs aset $# 1
	case "$1" in
	( *'['*']' )
		_msh_array_a=${1%%\[*}
		_msh_array_k=${1#*\[}; _msh_array_k=${_msh_array_k%]}
		case "$_msh_array_a$_msh_array_k" in
		( [!A-Za-z_]* | *[!A-Za-z0-9_]* )
			die "aunset: invalid array or key name" ;;
		esac
		test -r "$_msh_array_dir/$_msh_array_a/$_msh_array_k" || return 0
		rm "$_msh_array_dir/$_msh_array_a/$_msh_array_k"  || die "aunset: rm failed"
		;;
	( * )	case "$1" in
		( [!A-Za-z_]* | *[!A-Za-z0-9_]* )
			die "aunset: invalid array name" ;;
		esac
		test -d "$_msh_array_dir/$1" || return 0
		rm -r "$_msh_array_dir/$1" || die "aunset: rm -r failed"
		;;
	esac
}
