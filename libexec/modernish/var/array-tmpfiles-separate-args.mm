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
trap "rm -rf $_Msh_array_dir" EXIT


# _______ module functions ___________

aset() {
	test $# -eq 3 || _Msh_dieArgs aset $# 3 || return
	case "$1$2" in
	( [!A-Za-z_]* | *[!A-Za-z0-9_]* )
		die "aset: invalid array or key name" || return ;;
	esac
	if ! test -d "$_Msh_array_dir/$1"; then
		mkdir "$_Msh_array_dir/$1" \
		|| die "aset: mkdir failed for array $1" || return
	fi
	printf '%s\n' "$3" >| "$_Msh_array_dir/$1/$2" \
	|| die "aset: failed to store value in $1[$2]" || return
}

# aget: get the value of an array's key, storing it in $VAL.
aget() {
	test $# -eq 2 || _Msh_dieArgs aset $# 2 || return
	case "$1$2" in
	( [!A-Za-z_]* | *[!A-Za-z0-9_]* )
		die "aget: invalid array or key name" || return ;;
	esac

	test -r "$_Msh_array_dir/$1/$2" \
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
	} < "$_Msh_array_dir/$1/$2" \
	|| die "aget: can't read value $1/$2" || return

}

# adump: output the values of one or more keys to standard output.
# adump -k: output both keynames and values, separated by '='.


# aunset: unset a member of an array, or an entire array.
# Deliberately don't use "rm -rf" and "rm -f" because we should be having
# the proper permissions to do it without forcing. If not, there are bigger
# problems and the script should die.
aunset() {
	case $# in
	( 2 )	case "$1$2" in
		( [!A-Za-z_]* | *[!A-Za-z0-9_]* )
			die "aunset: invalid array or key name" || return ;;
		esac
		test -r "$_Msh_array_dir/$1/$2" || return 0
		rm "$_Msh_array_dir/$1/$2"  || die "aunset: rm failed" || return
		;;
	( 1 )	case "$1" in
		( [!A-Za-z_]* | *[!A-Za-z0-9_]* )
			die "aunset: invalid array name" || return ;;
		esac
		test -d "$_Msh_array_dir/$1" || return 0
		rm -r "$_Msh_array_dir/$1" || die "aunset: rm -r failed" || return
		;;
	( * )	_Msh_dieArgs aunset $# '1 or 2' || return ;;
	esac
}
