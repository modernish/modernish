#! /module/for/moderni/sh

# Functions for working with directories.
#
# TODO: reimplement pushd/popd/dirs from bash/zsh for other shells


# ----------

# countfiles <directory> [ <globpattern> ]:
# Count the number of files in a directory, storing the number in $REPLY.
# If <globpattern> is given, only count the files matching it.
# TODO: default to output on stdout; option for storing in variable.
countfiles() {
	case ${#} in
	( 0 )	die "countfiles: at least one argument must be given" || return ;;
	( 1 )	set -- "$1" '.[!.]*' '..?*' '*' ;;
	esac
	
	if not isdir -L "$1"; then
		die "countfiles: not a directory: $1" || return
	fi

	REPLY=0

	push IFS -f
	IFS=''
	set +f
	_Msh_cF_dir=$1
	shift
	not contains "$*" / || die "countfiles: Directories in patterns not supported." || return
	for _Msh_cF_pat do
		set -- "$_Msh_cF_dir"/$_Msh_cF_pat
		if exists "$1"; then
			let REPLY+=$#
		fi
	done
	unset -v _Msh_cF_pat _Msh_cF_dir
	pop IFS -f
}

# ----------

# traverse: Recursively walk through a directory, executing a command for
# each file found. Cross-platform, robust replacement for 'find'. Since the
# command name can be a shell function, any functionality of 'find' and
# anything else can be programmed in the shell language.
#
# Usage: traverse <dirname> <commandname>
#
# traverse calls <commandname>, once for each file found within the
# directory <dirname>, with one parameter containing the full pathname
# relative to <dirname>. Any directories found within are automatically
# entered and traversed recursively unless <commandname> exits with status
# 1. Symlinks to directories are not followed.
#
# find's '-prune' functionality is implemented by testing the command's exit
# status. If the command indicated exits with status 1 for a directory, this
# means: do not traverse the directory in question. For other types of
# files, exit status 1 is the same as 0 (success). Exit status 2 means: stop
# the execution of 'traverse' and resume program execution. An exit status
# greaterthan 2 indicates system failure and causes the program to abort.
#
# Inspired by myfind() in Rich's sh tricks, but improved (no subshells, no
# change of working directory, prune functionality, failure handling).

# TODO: implement functionality of 'find -depth'
# TODO: implement option to call handler function with multiple arguments
# TODO?: make into loop. (How? That's hard to do if we can't use "for".)
#	traverse f in ~/Documents; do
#		isreg $f && file $f
#	done

traverse() {
	eq "$#" 2 || die "traverse: incorrect number of arguments (got $#, expected 2)" || return
	exists "$1" || die "traverse: file not found: $1" || return
	command -v "$2" >/dev/null || die "traverse: command not found: $2" || return
	eval "$2 \"\$1\""
	case $? in
	( 0 )	if isdir -L "$1"; then
			case $- in
			( *f* )	set +f
				_Msh_doTraverse_f "$@"
				eval "set -f; unset -v _Msh_trV_F _Msh_trV_e; return $?"
				;;
			( * )	_Msh_doTraverse "$@"
				eval "unset -v _Msh_trV_F _Msh_trV_e; return $?"
				;;
			esac
		fi ;;
	( 1|2 )	;;
	( * )	die "traverse: command failed with status $?: $2" ;;
	esac
}

_Msh_doTraverse() {
	for _Msh_trV_F in "$1"/..?* "$1"/.[!.]* "$1"/*; do
		#if [ -L "$_Msh_trV_F" ] || [ -e "$_Msh_trV_F" ]; then
		if exists "$_Msh_trV_F"; then
			eval "$2 \"\$_Msh_trV_F\""
			_Msh_trV_e=$?
			case ${_Msh_trV_e} in
			( 0|1 )	;;
			( 2 )	return 2 ;;
			( * )	die "traverse: command failed with status ${_Msh_trV_e}: $2" || return ;;
			esac
		fi
		#if [ ! -L "$_Msh_trV_F" ] && [ -d "$_Msh_trV_F" ] && [ "${_Msh_trV_e}" -eq 0 ]; then
		if isdir "$_Msh_trV_F" && eq _Msh_trV_e 0; then
			_Msh_doTraverse "$_Msh_trV_F" "$2" || return
		fi
	done
}

_Msh_doTraverse_f() {
	for _Msh_trV_F in "$1"/..?* "$1"/.[!.]* "$1"/*; do
		#if [ -L "$_Msh_trV_F" ] || [ -e "$_Msh_trV_F" ]; then
		if exists "$_Msh_trV_F"; then
			set -f
			eval "$2 \"\$_Msh_trV_F\""
			_Msh_trV_e=$?
			set +f
			case ${_Msh_trV_e} in
			( 0|1 )	;;
			( 2 )	return 2 ;;
			( * )	die "traverse: command failed with status ${_Msh_trV_e}: $2" || return ;;
			esac
		fi
		#if [ ! -L "$_Msh_trV_F" ] && [ -d "$_Msh_trV_F" ] && [ "${_Msh_trV_e}" -eq 0 ]; then
		if isdir "$_Msh_trV_F" && eq _Msh_trV_e 0; then
			_Msh_doTraverse_f "$_Msh_trV_F" "$2" || return
		fi
	done
}
