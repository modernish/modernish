#! test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# Regression tests related to modernish utilities provided by sys/* modules
# as well as the modernish core.

# ... bin/modernish ...

TEST title='chdir copes with corner case dirnames'
	set -- - + -1 +1 -123 +123 -123a +123a
	chdir $tempdir
	mkdir -- "$@"
	for dir do
		v=$(chdir -f -- $dir 2>&1 && putln $PWD)
		case $v in
		( */"$dir" )
			;;
		( * )
			shellquote v
			failmsg="${failmsg-}${failmsg:+/}chdir -f -- $dir" ;;
		esac
	done
	chdir $OLDPWD
	not isset failmsg
ENDT

# ... sys/base/readlink ...
(
	umask 077	# macOS enforces read permissions on symlinks!
	mkcd $tempdir/sym
	ln -s recurse1 recurse2
	ln -s recurse2 recurse1
	umask 777
	ln -s ///.//..///$MSH_PREFIX//./bin/../lib/modernish noperms
)

TEST title='readlink: -m goes past recursive symlink'
	readlink -s -m $tempdir/sym/recurse1/.//../../sym/recurse1/foo/quux/../../../recurse2/bar/baz//
	if not str eq $REPLY $tempdir/sym/recurse2/bar/baz; then
		shellquote -f failmsg=$REPLY
		return 1
	fi
ENDT

TEST title='readlink: symlink permissions enforced?'
	readlink -s -e ///..//.///$tempdir/sym//.././sym//noperms
	if so; then
		# The symlink was read, in spite of no perms (all known systems except macOS).
		str eq $REPLY $MSH_PREFIX/lib/modernish && okmsg=no && return
		# If a symlink cannot be read (due to no perms on macOS, or recursion), then GNU 'readlink -e' ("all pathname
		# components must exist") and '-f' ("all pathname components but the last must exist") always return no result and
		# a nonzero status. That makes no sense, considering that GNU -e and -f don't require the file to be a symlink at
		# all and happily return the file for nonsymlink arguments. Modernish considers an unreadable symlink to exist as
		# such, so returns the symlink. This is both more logical, and more consistent with the GNU documentation!
		str eq $REPLY $tempdir/sym/noperms && okmsg=yes && return
	fi
	shellquote -f failmsg=${REPLY-}
	return 1
ENDT

TEST title="readlink: perms enforced whl traversing?"
	# Are symlink permissions enforced while traversing a symlink to a directory as a pathname component?
	readlink -s -e ///..//.///$tempdir/sym//.././sym//noperms//
	if so; then
		str eq $REPLY $MSH_PREFIX/lib/modernish && okmsg=no && return
		str eq $REPLY /$MSH_PREFIX/lib/modernish && { xfailmsg=no; mustHave BUG_CDPCANON; return; }
		str eq $REPLY $tempdir/sym/noperms && okmsg=yes && return  # on macOS: zsh, ksh, mksh, but not bash, dash, yash
	fi
	shellquote -f failmsg=${REPLY-}
	return 1
ENDT

TEST title='readlink: symlinks in $PWD are resolved'
	# chdir into a symlink to a directory, canonicalise a path within it, check the symlink in $PWD is resolved.
	v=$(
		umask 077
		mkdir -p $tempdir/sym/d1/d2
		ln -s d1 $tempdir/sym/sym2dir
		chdir -fL $tempdir/sym/sym2dir || exit 1
		readlink -f d2
	) || return 1
	failmsg=$v
	str eq $v $tempdir/sym/d1/d2
ENDT

# ... sys/base/tac ...

TEST title='tac: default'
	v=$(put un${CCn}duo${CCn}tres | tac; put X)	# defeat stripping of final linefeed by cmd. subst.
	str eq $v tresduo${CCn}un${CCn}X
ENDT

TEST title='tac -b'
	v=$(put un${CCn}duo${CCn}tres | tac -b)
	str eq $v ${CCn}tres${CCn}duoun
ENDT

TEST title='tac -B'
	v=$(put un${CCn}duo${CCn}tres | tac -B)
	str eq $v tres${CCn}duo${CCn}un
ENDT

TEST title='tac -r -s, with bound in ERE'
	v=$(put un!duo!!tres!!!quatro!!!!cinque!!!!!sex!!!!!! | tac -r -s '!{3,}')
	str eq $v sex!!!!!!cinque!!!!!quatro!!!!un!duo!!tres!!!
ENDT

TEST title='tac -b -r -s'
	v=$(put !un!!duo!!!tres!!!!quatro | tac -b -r -s '!+')
	str eq $v !!!!quatro!!!tres!!duo!un
ENDT

TEST title='tac -B -r -s'
	v=$(put un!duo!!tres!!!quatro!!!! | tac -B -r -s '!+')
	str eq $v !!!!quatro!!!tres!!duo!un
ENDT

TEST title='tac: trailing whitespace'
	v=$(put "1 2 3 " | tac -s " ")
	str eq $v "3 2 1 "
ENDT

TEST title='tac: leading whitespace'
	v=$(put " 1 2 3" | tac -s " ")
	str eq $v "32 1  "
ENDT

# ... sys/cmd/mapr ...

TEST title='mapr: read all the lines of a text file'
	runExpensive || return
	foo=
	foo() {
		push IFS
		IFS=$CCn
		foo=$foo"$*"$CCn  # quote "$*" for BUG_PP_* compat
		pop IFS
	}
	mapr foo < $MSH_MDL/safe.mm || return 1
	trim foo $CCn
	str eq $foo $(cat $MSH_MDL/safe.mm)
ENDT

TEST title='mapr: skip, limit and quantum'
	v=$(putln "\
     1	y
     2	y
     3	y
     4	y
     5	y
     6	y
     7	y
     8	y
     9	y
    10	y
    11	y
    12	y
    13	y
    14	y
    15	y" | mapr -s 3 -n 10 -c 4 printf '\t\t[%s]\n' '--------')

	str eq $v "\
		[--------]
		[     4	y]
		[     5	y]
		[     6	y]
		[     7	y]
		[--------]
		[     8	y]
		[     9	y]
		[    10	y]
		[    11	y]
		[--------]
		[    12	y]
		[    13	y]"
ENDT

TEST title='mapr: delim;max total length;abort exec'
	foo() {
		printf '%s,' "$@"
		return 255  # abort
	}
	v=$(put " 1${CCt}y/ 2${CCt}y/ 3${CCt}y/ 4${CCt}y/ 5${CCt}y/ 6${CCt}y/ " | mapr -d / -m 25 foo)
	if ne $? 255; then
		failmsg='bad exit status'
		return 1
	fi
	str eq "$v" " 1${CCt}y, 2${CCt}y, 3${CCt}y, 4${CCt}y,"
ENDT

TEST title='mapr: max length per batch, args aligned'
	runExpensive || return
	OutputOneBatch() {
		IFS=; v="$*"
		extern -p printf %s "$@" || return
		return 255  # abort
	}
	LOCAL v test_arg='' max_len result arg_len arg_len_algn expected_num cmd_name; BEGIN
		max_len=$(MSH_NOT_FOUND_OK=y; PATH=$DEFPATH exec getconf ARG_MAX 2>/dev/null) || max_len=262144
		gt max_len/8 2048 && dec max_len max_len/8 || dec max_len 2048
		if ne max_len _Msh_mapr_max; then
			failmsg="wrong ARG_MAX"
			return 1
		fi
		# On macOS, arguments are aligned on 8 byte boundaries and have an 8 byte length count each.
		# We also have to account for 1 extra byte for the 0 byte that terminates a C string.
		# Hopefully there is no system that aligns its arguments to even wider intervals.
		cmd_name=OutputOneBatch
		let "arg_len = ${RANDOM:-$$} % 256 + 1" \
			"v = arg_len + 1" \
			"v = (v % 8 == 0) ? v : (v - v % 8 + 8)" \
			"arg_len_algn = v + 8" \
			"v = ${#cmd_name} + 1" \
			"v = (v % 8 == 0) ? v : (v - v % 8 + 8)" \
			"cmd_len_algn = v + 8" \
			"expected_num = (max_len - cmd_len_algn) / arg_len_algn"
		while lt ${#test_arg} arg_len; do
			test_arg=${test_arg}x
		done
		result=$(use sys/base/yes && yes $test_arg | mapr $cmd_name)
		if ne $? 255; then
			failmsg='bad exit status'
			return 1
		fi
		if let "${#result} > expected_num * arg_len"; then
			failmsg='batch too long'
			return 1
		fi
	END
ENDT
