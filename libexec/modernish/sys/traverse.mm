#! /module/for/moderni/sh

# traverse: safely traverse through a directory, executing a command for
# each file. Easy to use robust replacement for 'find'.
#
# Inspired by myfind() in Rich's sh tricks, but improved (no subshells, no
# change of working directory).

# TODO?: make into loop. (How? That's hard to do if we can't use "for".)
#	traverse f in ~/Documents; do
#		isreg $f && file $f
#	done

traverse() {
	eq "$#" 2 || die "traverse: incorrect number of arguments (got $#, expected 2)" || return
	issymlink "$1" || exists "$1" || die "traverse: not found: $1" || return
	push IFS -f -u -C _Msh_trV_F
	IFS=''; set +f -u -C
	eval "$2 \"\$1\"" || die "traverse: command failed: $2" || return
	if isdir -L "$1"; then
		_Msh_doTraverse "$@"
	fi
	eval "pop IFS -f -u -C _Msh_trV_F; return $?"
}

_Msh_doTraverse() {
	for _Msh_trV_F in "$1"/..?* "$1"/.[!.]* "$1"/*; do
		if [ -L "$_Msh_trV_F" ] || [ -e "$_Msh_trV_F" ]; then
			set -f
			eval "$2 \"\$_Msh_trV_F\"" || die "traverse: command failed: $2" || return
			set +f
		fi
		if [ ! -L "$_Msh_trV_F" ] && [ -d "$_Msh_trV_F" ]; then
			_Msh_doTraverse "$_Msh_trV_F" "$2" || return
		fi
	done
}
