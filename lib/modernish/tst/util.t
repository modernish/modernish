#! test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# Regression tests related to modernish utilities provided by sys/* modules.

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

TEST title='tac -r -s'
	v=$(put un!duo!!tres!!!quatro!!!! | tac -r -s '!*')
	str eq $v quatro!!!!tres!!!duo!!un!
ENDT

TEST title='tac -b -r -s'
	v=$(put !un!!duo!!!tres!!!!quatro | tac -b -r -s '!*')
	str eq $v !!!!quatro!!!tres!!duo!un
ENDT

TEST title='tac -B -r -s'
	v=$(put un!duo!!tres!!!quatro!!!! | tac -B -r -s '!*')
	str eq $v !!!!quatro!!!tres!!duo!un
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

TEST title='readlink -m goes past recursive symlink'
	readlink -s -m $tempdir/sym/recurse1/.//../../sym/recurse1/foo/quux/../../../recurse2/bar/baz//
	if not str eq $REPLY $tempdir/sym/recurse2/bar/baz; then
		shellquote -f failmsg=$REPLY
		return 1
	fi
ENDT

TEST title='Permissions enforced reading symlinks?'
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

TEST title="Permiss'ns enforced traversing symlinks?"
	readlink -s -e ///..//.///$tempdir/sym//.././sym//noperms//
	if so; then
		str eq $REPLY $MSH_PREFIX/lib/modernish && okmsg=no && return
		str eq $REPLY /$MSH_PREFIX/lib/modernish && { xfailmsg=no; mustHave BUG_CDPCANON; return; }
		str eq $REPLY $tempdir/sym/noperms && okmsg=yes && return  # on macOS: zsh, ksh, mksh, but not bash, dash, yash
	fi
	shellquote -f failmsg=${REPLY-}
	return 1
ENDT
