#! moderni/sh
# An alias + internal function pair for a simple 'repeat' loop. Turns out
# zsh has a 'repeat' just like this one built in! So let's first test if we
# already have a functioning 'repeat'. (Use 'eval' to avoid the shell
# bombing out on a syntax error in the pre-parsing phase.)
# BUG:	Breaking out of a 'repeat' loop causes a stack leak. This is
#	fundamentally unsolvable because we can't intercept reserved shell
#	keywords "while", "do" or "done" to keep track of what level of loop
#	we're in. As a mitigation, "breakrepeat" is provided for use in
#	"repeat" loops and the use of "break" is considered invalid. But it
#	can support only one level of break, because we have no way of
#	knowing if any enclosing loops are also 'repeat' loops or not. Plus,
#	it is unenforceable, so memory leaks still occur if programmers
#	forget this. This whole thing is probably a failed idea.
_Msh_R=0
_Msh_savePATH=$PATH
PATH=''
eval 'repeat 3; do _Msh_R=$((_Msh_R+1)); done' >/dev/null 2>&1
if ne $? 0 || ne ${_Msh_R} 3; then
	alias repeat='push _Msh_R && _Msh_R=0 && while _Msh_doR'
	alias breakrepeat='_Msh_doRbr'
	_Msh_doR() {
		if ! [ "${_Msh_R}" -lt "${1:-0}" ]; then
			pop _Msh_R
			return 1
		fi
		_Msh_R=$((_Msh_R+1))
	}
	_Msh_doRbr() {
		pop _Msh_R || return
		break
	}
else
	alias breakrepeat='break'
fi
PATH=${_Msh_savePATH}
unset -v _Msh_savePATH _Msh_R

