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
	not isset -v var && not isset -x var
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

# Tests to verify feature detection related to variables.

TEST title="VARPREFIX feature detection"
	if ! (eval ': ${!foo_@} ${!foo_*}') 2>/dev/null; then
		mustNotHave VARPREFIX && mustNotHave BUG_VARPREFIX
		return
	fi
	foobar=baz foo_interfere=h3h3h3
	eval 'unset -v ${!foo@}'
	foo=theprefix foo_one=1 foo_two=2 foo_3=three
	push IFS
	IFS=/
	eval 'v=${!foo*}'
	pop IFS
	eval 'set -- ${!foo@}'
	v=$v,$#,${1-},${2-},${3-},${4-}
	case $v in
	( foo/foo_3/foo_one/foo_two,4,foo,foo_3,foo_one,foo_two )
		mustHave VARPREFIX && mustNotHave BUG_VARPREFIX ;;
	( foo_3/foo_one/foo_two,3,foo_3,foo_one,foo_two, )
		mustHave VARPREFIX && mustHave BUG_VARPREFIX ;;
	( * )	failmsg=$v
		return 1 ;;
	esac
ENDT
