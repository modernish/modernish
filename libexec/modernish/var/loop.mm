#! /module/for/moderni/sh


# Here-documents using <<"delimiter" with quotes are perfectly
# shell-quoted already, so we can feed them into 'eval' without
# further processing.

# PROBLEM: The here-document delimeter is syntactically problematic for this
# purpose, to say the least. Must be on a line by itself. Must use only
# tabs, no other blanks. Failure to observe this causes wildly wrong
# behaviour rather than sane exception handling.
#
# One way to mitigate this is stop trying to hide that this is a
# here-document and just accept it as a feature. So, no alias:
# alias loop='_msh_doLoop <<-"endloop"'
# But: people might forget the essential quotes around the delimiter
# to quote the here-document, and then "eval" can wreak havoc.

#_msh_doLoop()
hereloop()
{
	push _msh_L_Var _msh_L_Val1 _msh_L_Cmp _msh_L_Val2

	_msh_L_Var='i'
	_msh_L_Val1='1'
	_msh_L_Cmp='le'
	_msh_L_Val2='10'

	IFS='' read -r _msh_L_Payload \
	&& while IFS='' read -r _msh_L_Line; do
		_msh_L_Payload="${_msh_L_Payload}${CC_n}${_msh_L_Line}"
	done
	eval "	${_msh_L_Var}=1
		while [ \$${_msh_L_Var} -${_msh_L_Cmp} ${_msh_L_Val2} ]; do
			${_msh_L_Payload}
			${_msh_L_Var}=\$((${_msh_L_Var} + 1))
		done"
	unset -v _msh_L_Payload _msh_L_Line

	pop _msh_L_Var _msh_L_Val1 _msh_L_Cmp _msh_L_Val2
}

	hereloop i=1 to 10 <<-"endloop"
		echo "hi there, it's $i"
	endloop
	echo the end
	echo well, this fails
