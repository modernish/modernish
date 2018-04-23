#! /shell/quirk/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# QRK_ARITHEMPT: In yash, with POSIX mode turned off, a set but empty
# variable yields an empty string when used in an arithmetic expression,
# instead of 0.
_Msh_test=''
(	# subshell for BUG_ARITHINIT compat
	case $((_Msh_test)) in
	( '' )	;;
	( * )	! : ;;
	esac
) 2>/dev/null || return 1
