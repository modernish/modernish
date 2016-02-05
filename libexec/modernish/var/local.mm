#! /bin/ksh
# Test if this shell supports local variables. If not, provide a substitute using the stack.
# (As far as I know, this is only ksh.)
#testlocal() { local testvar=1 && test $testvar -eq 1; }
#testlocal 2>/dev/null
#if not; then


# stack-based local vars

local() {
	_Msh_localvars=''
	for _Msh_v; do
		push "${_Msh_v%%=*}"	# 'push' does validation already
		case "${_Msh_v}" in
		*=* )	# TODO: 'shell'\''quote' part after =
			eval "${_Msh_v}" ;;
		* )	unset ${_Msh_v} ;;
		esac
		_Msh_localvars="$_Msh_localvars ${_Msh_v%%=*}"
	done
	push -_Msh_localvars
	unset _Msh_v
}

endlocal() {
	pop _Msh_localvars || return
	push IFS
	IFS=' '
	pop ${_Msh_localvars}
	pop IFS
	unset _Msh_localvars
}




#else
#	# dummy
#	endlocal() {
#		:
#	}
#fi
#unset -f testlocal
