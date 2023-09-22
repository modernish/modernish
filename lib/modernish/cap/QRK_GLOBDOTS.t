#! /shell/quirk/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# QRK_GLOBDOTS: pathname expansion of '.*' harmfully matches the special
# navigational names '.' and '..' (bash < 5.2, (d)ash, AT&T ksh < 93u+m, yash)

(
	cd /dev
	set +o noglob
	set -- .?
	for _Msh_test do
		case ${_Msh_test} in
		( .. )	exit 0 ;;
		esac
	done
	exit 1
)
