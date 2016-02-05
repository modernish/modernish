#! /module/for/moderni/sh
# Harden 'test', catching command errors (exit status > 1).
# Note: does not work on ksh for shell arithmetic as ksh doesn't correctly
# return status > 1 for errors.
# Unfortunately, hardening [ in the same way is impossible
# because [ is not accepted as a function name.
# Note: if function gets to the end, exit status is always 1

[ '1.5' -eq 'invalid' ] 2>| /dev/null
case $? in
( 0 )
	die "harden/test.mm init: internal error" || return
	;;
( 1 )
	# We have a 'test'/'[' that does not correctly return an error (2 or
	# greater) status if invalid arguments are given. ('ksh93' is the
	# offender that I know of.) This makes it impossible to distinguish
	# between 'not true' results and errors by exit status. The only
	# indication is an error message printed to standard output. So, to
	# be robust *and* stay compatible with ksh93, check standard error
	# output with a command substitution and die if any output is
	# produced. This comes at the cost of launching a subshell.
	#
	# A faster alternative would be to write the result to a
	# session-permanent temp file and then check if the file is empty.
	# However, this introduces a race condition if 'test' is used in
	# parallel processing. There is no way around this that wouldn't
	# cause a bigger performance hit than a subshell does.
	test() {
		_Msh_test_Err="$([ "$@" ] 2>&1)" && return
		[ -n "${_Msh_test_Err}" ] && {
			printf '%s\n' "${_Msh_test_Err}" 1>&2
			die "test: '[' failed"
		}
	}
	;;
( * )
	# The sane version, for correctly functioning test/[.
	test() {
		[ "$@" ] && return
		[ $? -gt 1 ] && die "test: '[' failed"
	}
	;;
esac
