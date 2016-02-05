#! /bin/sh

catchfail() {
	_msh_catchfail_test="$1"  # some ash/dash need quotes here to not b0rk on variable name within variable
	shift   
	#set +e
	command "$@"
	_msh_catchfail_status=$?
	#set -e		# TODO: how to save set {-,+}e state?
	eval "$_msh_catchfail_test" || die "failed \"$_msh_catchfail_test\" with status $_msh_catchfail_status: $@"
	return $_msh_catchfail_status
}
