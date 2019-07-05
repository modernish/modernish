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
