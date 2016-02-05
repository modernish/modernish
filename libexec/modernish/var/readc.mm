#! /module/for/moderni/sh

: <<'~~~endcomment~~~'
	readc is like read, but reads the output of a command into a
	variable, instead of user input.

	readc helps eliminate the need for launching subshells by providing
	an alternative for command substitution that launches zero subshells
	or other external processes. This function uses a temporary file
	instead, which is much faster.

	NOTE:	Most shells optimize for command substitutions containing
		only 1 external command, skipping the subshell and launching
		just that external command. So command substitution will
		usually be faster for those. But if a shell builtin, shell
		function, loop, or anything more complex than a simple
		external command is used, then this is faster.

	Usage: readc [ -L ] <varname> <commandarg> [ <commandarg> ... ]
	The command should not be quoted as a whole, but given as one or
	more separate arguments, e.g.: readc MyFiles glob ls /dir/*.txt

	When used with set -f and 'glob', the above order is preferred,
	because the other possibility 'glob readc MyFiles ls /dir/*.txt'
	causes readc to need to shell-quote each argument expanded from
	*.txt, which will cause a significant performance hit if there are
	many files.

	Uses atomic locking, so it is safe for parallel processing.
~~~endcomment~~~

# ----------------------

echo "DEBUG: $?"

# --- Initialization ---
# Create temp dir and set cleanup trap.
if not isset _Msh_readc_TMP; then
	_Msh_readc_TMP=$(mktemp -d /tmp/_Msh_readc_XXXXXX) \
		&& isdir ${_Msh_readc_TMP} \
		&& canwrite ${_Msh_readc_TMP} \
		|| die 'var/readc: init: mktemp failed' || return
	readonly _Msh_readc_TMP
	pushtrap "rm -rf ${_Msh_readc_TMP}" EXIT || return
fi

# --- The function ---
readc() {
	[ "${1:-}" = "-L" ] && _Msh_readc_optL=y && shift || _Msh_readc_optL=''
	[ $# -ge 2 ] || _Msh_dieArgs readc $# 'at least 2 (excl. -L option)' || return
	case "$1" in
	( '' | [!a-zA-Z_]* | *[!a-zA-Z0-9_]* )
		die "readc: invalid variable name: ${1#-}" || return ;;
	esac

	_Msh_readc_VAR="$1"
	shift

	# Quote every shell argument separately for 'eval'.
	# (TODO?: make function that shell-quotes every <arg> and stores them into <varname>)
	_Msh_readc_CMD="$1"
	quotevar _Msh_readc_CMD
	shift
	while [ $# -gt 0 ]; do
		_Msh_readc_ARG="$1"
		quotevar _Msh_readc_ARG
		_Msh_readc_CMD="${_Msh_readc_CMD} ${_Msh_readc_ARG}"
		shift
	done

	case $- in
	( *C* ) _Msh_readc_CLOB='' ;;
	( * )	set -C; _Msh_readc_CLOB=y ;;
	esac

	# Safety for parallel processing: practice atomic locking by opening
	# a file descriptor under 'set -C' (noclobber) and blocking this
	# process until that succeeds. Reduce blocking delays by trying to
	# find a unique filename while we're blocked. If we have $RANDOM, use
	# it to expedite the process, otherwise just iterate through all
	# possibilities one by one starting with 0.
	_Msh_readc_S=0
	until exec 7>${_Msh_readc_TMP}/${_Msh_readc_S}${_Msh_readc_VAR}; do
		_Msh_readc_S=$(( _Msh_readc_S + ${RANDOM:-1} ))
	done 2>/dev/null

	# Execute the command, sending standard output (1) to the open file (7).
	eval "${_Msh_readc_CMD}" 1>&7
	_Msh_readc_status=$?

	# Close the file descriptor.
	exec 7<&-

	# Read the output and store it in the specified variable.
	{ IFS='' read -r _Msh_readc_OUT \
		&& while IFS='' read -r _Msh_readc_LINE; do
			_Msh_readc_OUT="${_Msh_readc_OUT}${CC_n}${_Msh_readc_LINE}"
		done
	} < ${_Msh_readc_TMP}/${_Msh_readc_S}${_Msh_readc_VAR}

	# Now remove the file (in the background to increase the performance
	# of our own process).
	rm ${_Msh_readc_TMP}/${_Msh_readc_S}${_Msh_readc_VAR} &

	# Strip final linefeeds as in command substitution, unless -L is given.
	if [ -z "${_Msh_readc_optL}" ]; then
		while [ "${_Msh_readc_OUT}" != "${_Msh_readc_OUT%%$CC_n}" ]; do
			_Msh_readc_OUT="${_Msh_readc_OUT%%$CC_n}"
		done
	else
		_Msh_readc_OUT="${_Msh_readc_OUT}${CC_n}"
	fi

	# Store the result in the specified variable.
	eval "${_Msh_readc_VAR}=\"\${_Msh_readc_OUT}\""

	# Restore previous clobber setting.
	if [ -z "${_Msh_readc_CLOB}" ]; then
		set +C
	fi

	unset -v _Msh_readc_VAR \
		_Msh_readc_S \
		_Msh_readc_ARG \
		_Msh_readc_CMD \
		_Msh_readc_OUT \
		_Msh_readc_LINE \
		_Msh_readc_optL \
		_Msh_readc_CLOB

	# Pass on the exit status of the executed command.
	eval "unset -v _Msh_readc_status; return ${_Msh_readc_status}"
}

readc_stresstest() {
	i=0; while [ $i -le 50 ] && i=$((i+1)); do
		{
			mypid=$(getmypid)
			exec >${_Msh_readc_TMP}/stresstest.$mypid 2>&1
			set -x
			readc testvar printf '%s\n' "This is a test for pid $mypid."
			[ "$testvar" = "This is a test for pid $mypid." ] || printf 'FAILFAILFAIL\n'
		} &
	done
}
