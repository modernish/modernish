#! /module/for/moderni/sh
# Find the current user's login shell. Try various platform-specific ways.
# Either outputs the login shell, or (on error) returns with status 2.
# TODO: implement getting login shell for another user.
# ...GNU, *BSD, Solaris
unset -f getent finger perl 2>/dev/null	# zsh defines a broken getent function by default
if command -v getent; then
	# Globbing applies to the result of an unquoted command substitution,
	# and passwd fields often contain a '*', so turn off globbing.
	loginshell() (
		le "$#" 1 || _Msh_dieArgs loginshell "$#" '0 or 1' || return
		set -f
		IFS=:
		set -- "${1-$USER}" $(getent passwd "${1-$USER}")
		eq "$#" 8 || exit 2
		if same "$2" "$1" && canexec "$8"; then
			print "$8"
		else
			exit 2
		fi
	)
# ...Mac OS X
elif canexec /usr/bin/dscl && isdir /System/Library/DirectoryServices; then
	loginshell() (
		le "$#" 1 || _Msh_dieArgs loginshell "$#" '0 or 1' || return
		set -f
		IFS="$WHITESPACE"
		set -- $(/usr/bin/dscl . -read "/Users/${1-$USER}" UserShell) || exit 2
		eq "$#" 2 || exit 2
		if same "$1" 'UserShell:' && canexec "$2"; then
			print "$2"
		else
			exit 2
		fi
	)
# ...finger
elif command -v finger; then
	loginshell() {
		le "$#" 1 || _Msh_dieArgs loginshell "$#" '0 or 1' || return
		set -- "$(LC_ALL=C finger -m "${1-$USER}" \
			| awk '{
				verified = false;
				if ( $1 == "Login:" && $2 == "${1-$USER}" )
					verified = true;
				if ( $3 == "Shell:" && verified == true ) {
					print $4;
					exit;
				}
			}')"
		if canexec "$1"; then
			print "$1"
		else
			return 2
		fi
	}
# ...Perl
elif command -v perl; then
	loginshell() {
		le "$#" 1 || _Msh_dieArgs loginshell "$#" '0 or 1' || return
                set -- "$(perl -e "print +(getpwnam \"${1-$USER}\")[8], \"\\n\"")"
		if canexec "$1"; then
			print "$1"
		else
			return 2
		fi
	}
# ...we don't have a way
else
	loginshell() {
		le "$#" 1 || _Msh_dieArgs loginshell "$#" '0 or 1' || return
		return 3
	}
fi >/dev/null 2>&1
