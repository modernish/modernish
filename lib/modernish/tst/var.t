#! test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# Regression tests for functions provided by modernish var/* modules.

# ... var/assign ...

TEST title="'assign' keeps variables global"
	fn() {
		v=i
		assign v=foo $v==baz -r j=$v +r var=\ bar
	}
	fn
	case ${v-},${var-},${i-},${j-} in
	( foo,\ bar,=baz,=baz )
		;;
	( * )	return 1 ;;
	esac
ENDT

# ... var/unexport ...

TEST title="remove export flag from unset var"
	unset -v var
	export var
	unexport var
	if not isset -v var && not isset -x var; then
		mustNotHave BUG_NOUNSETEX
	elif isset -v var && not isset -x var; then
		mustHave BUG_NOUNSETEX
	else
		return 1
	fi
ENDT

TEST title='remove export flag from set var'
	export var='foo'
	unexport var
	not isset -x var && str eq $var 'foo'
ENDT

TEST title='assign new value while unexporting'
	export var='bar'
	unexport var='baz'
	not isset -x var && str eq $var 'baz'
ENDT
