#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_CMDEXEC: using 'command exec' (to open a file descriptor, using
# 'command' to avoid exiting the shell on failure) within a function causes
# old bash versions to fail to restore the global positional parameters when
# leaving that function. IOW, the function's PPs just became global.
#
# Triggering this bug also leaves the shell in an inconsistent internal
# state, making it prone to hanging or crashing. Thus, no workaround is
# feasible except for not executing 'command exec' on bash with this bug.
# Unfortunately, other shells require this to avoid exiting on error.
# Thankfully, the 'exec' on old bash versions is not POSIX-compliant
# and won't exit the shell on error, so you don't need it there...
# Thus, the workaround goes something like:
#	thisshellhas BUG_CMDEXEC && exec 3<myFIFO || command exec 3<myFIFO
#
# Bug found on: bash <= 4.0.*

(	# We want a subshell to stop the bug from affecting the main shell.
	_Msh_testFn() {
		command exec
	}

	set --
	_Msh_testFn x
	case ${#},${1-} in
	( 1,x )	;;
	( * )	\exit 1 ;;
	esac
)
