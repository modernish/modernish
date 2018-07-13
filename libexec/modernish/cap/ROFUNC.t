#! /shell/capability/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# ROFUNC: Set functions to read-only with 'readonly -f'. (bash, yash)
case $(
	_Msh_roFn() { PATH=$DEFPATH command echo RO; }
	readonly -f _Msh_roFn
	_Msh_roFn() { :; }
	_Msh_roFn
) in
( RO )	;;
( * )	return 1 ;;
esac 2>/dev/null
