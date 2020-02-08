#! /install/script/for/moderni/sh
#
# This is dotted/sourced by install.sh to bundle a script.
# See the file LICENSE in the main modernish directory for the licence.

# In case someone tries to run this directly...
PATH=/dev/null command -v install_file >/dev/null || exit

# ----- functions -----

# Covert all the tiny cap/*.t scripts into shell functions, and insert them into bin/modernish.
# (The lib/_install/bin/modernish.bundle.diff patch changed thisshellhas() to use these functions, and to
# remove --cache and --show because now we can't use lib/modernish/cap/*.t to know what all our IDs are.)
link_cap_tests() {
	put_wrap "- Static linking of cap tests:"
	num_captests=0
	LOOP for --glob cap in ${opt_D}$installroot/lib/modernish/cap/*.t; DO
		inc num_captests
		capname=${cap##*/cap/}
		capname=${capname%.t}
		put_wrap "  $capname"
		str match $capname *[!ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_]* && continue
		code=$(sed '1 d' $cap)	# omit line 1 = hashbang
		trim code $CCn		# remove leading blank lines
		putln "_Msh_CAP_$capname() {" $code "}" >&3
	DONE 3>$tmpdir/captests

	# This tag was patched in from lib/_install/bin/modernish.bundle.diff.
	# Now we sed it back out, replacing it with the hardlinked cap tests.
	sed "/@INSERT_CAPTESTS_HERE@/ {
		r $tmpdir/captests
		d
	}" ${opt_D}$installroot/bin/modernish >| $tmpdir/patched:bin:modernish || die

	# 'sed' doesn't even give an error message or a nonzero status if the 'r'
	# command fails to read the file, so we have to check the results.
	num_captests_ok=$(grep -c '^_Msh_CAP_.*() {$' $tmpdir/patched:bin:modernish)
	if not eq num_captests_ok num_captests; then
		putln '' "  --  FAIL"
		die "Static linking FAILED: $num_captests processed, $num_captests_ok linked"
	fi

	cat $tmpdir/patched:bin:modernish >| ${opt_D}$installroot/bin/modernish || die
	put_wrap "  --  done ($num_captests)."
	putln; column_pos=0
	rm -r ${opt_D}$installroot/lib/modernish/cap <&-
}

# Generate and install a wrapper script that runs a bundled program with modernish.
# usage: install_wrapper_script SCRIPTBASENAME SHELLQUOTED_SCRIPTBASENAME
install_wrapper_script() {
	install_file - $opt_D/$1 <<-end_of_wrapper
	#! /bin/sh
	# Wrapper script to run $2 with bundled modernish

	min_posix='! { ! case x in ( x ) : \${0##*/} || : \$( : ) ;; esac; }'
	if (eval "\$min_posix") 2>/dev/null; then
	 	unset -v min_posix
	else
	 	# this is an ancient Bourne shell (e.g. Solaris 10)
	 	sh -c "\$min_posix" 2>/dev/null && exec sh -- "\$0" \${1+"\$@"}
	 	DEFPATH=\`getconf PATH\` 2>/dev/null || DEFPATH=/usr/xpg4/bin:/bin:/usr/bin:/sbin:/usr/sbin
	 	PATH=\$DEFPATH:\$PATH
	 	export PATH
	 	sh -c "\$min_posix" 2>/dev/null && exec sh -- "\$0" \${1+"\$@"}
	 	echo "\$0: Can't escape from obsolete shell. Run me with a POSIX shell." >&2
	 	exit 128
	fi

	unset -v CDPATH DEFPATH IFS MSH_PREFIX MSH_SHELL	# avoid these being inherited/exported
	CCn='
	'

	# Find bundled modernish.
	# ... First, if \$0 is a symlink, resolve the symlink chain.
	case \$0 in
	( */* )	linkdir=\${0%/*} ;;
	( * )	linkdir=. ;;
	esac
	me=\$0
	while test -L "\$me"; do
	 	newme=\$(command ls -ld -- "\$me" && echo X)
	 	case \$newme in
	 	( *" \$me -> "*\${CCn}X ) ;;
	 	( * )	echo "\$0: resolve symlink: 'ls -ld' failed" >&2
	 		exit 128 ;;
	 	esac
	 	newme=\${newme#*" \$me -> "}
	 	newme=\${newme%\${CCn}X}
	 	case \$newme in
	 	( /* )	me=\$newme ;;
	 	( * )	me=\$linkdir/\$newme ;;
	 	esac
	 	linkdir=\${me%/*}
	done
	# ... Find my absolute and physical directory path.
	case \$me in
	( */* )	MSH_PREFIX=\${me%/*} ;;
	( * )	MSH_PREFIX=. ;;
	esac
	case \$MSH_PREFIX in
	( */* | [!+-]* | *[!0123456789]* )
	 	MSH_PREFIX=\$(cd -- "\$MSH_PREFIX" && pwd -P && echo X) ;;
	( * )	MSH_PREFIX=\$(cd "./\$MSH_PREFIX" && pwd -P && echo X) ;;
	esac || exit
	MSH_PREFIX="\${MSH_PREFIX%?X}"${installroot_q:+$installroot_q}

	# Get the system's default path.
	. "\$MSH_PREFIX/lib/modernish/aux/defpath.sh" || exit

	$(if isset opt_s; then putln \
		"# Verify preferred shell. Try this path first, then a shell by this name, then others." \
		"MSH_SHELL=$msh_shell" \
		". \"\$MSH_PREFIX/lib/modernish/aux/goodsh.sh\" || exit" \
		"case \$MSH_SHELL in" \
		"( */${msh_shell##*/} )	;;" \
		"( * )	echo $2: \"warning: ${msh_shell##*/} shell not usable; running on \$MSH_SHELL\" >&2 ;;" \
		"esac"
	else putln \
		"# Find a good shell." \
		"unset -v MSH_SHELL" \
		". \"\$MSH_PREFIX/lib/modernish/aux/goodsh.sh\" || exit"
	fi)

	# Prefix launch arguments.
	$(
		read -r hashbang < $script 1>&1 || die	# the 1>&1 stops ksh93 segfaulting by forcing the cmd subst to fork
		if str ematch $hashbang "/env[[:blank:]]+modernish"; then
			# Portable-form script
			putln "set -- \"\$MSH_PREFIX/bin/modernish\" \"\$MSH_PREFIX\"/bin/$2 \"\$@\""
		else
			# Simple-form script
			putln "set -- \"\$MSH_PREFIX\"/bin/$2 \"\$@\"" \
				"PATH=\$MSH_PREFIX/bin:\$PATH	# make '. modernish' work"
		fi
	)

	# Run bundled script.
	export "_Msh_PREFIX=\$MSH_PREFIX" "_Msh_SHELL=\$MSH_SHELL" "_Msh_DEFPATH=\$DEFPATH"
	unset -v MSH_PREFIX MSH_SHELL DEFPATH	# avoid exporting these
	test -d "\${XDG_RUNTIME_DIR-}" && case \$XDG_RUNTIME_DIR in (/*) ;; (*) ! : ;; esac || unset -v XDG_RUNTIME_DIR
	test -d "\${TMPDIR-}" && case \$TMPDIR in (/*) ;; (*) ! : ;; esac || unset -v TMPDIR
	case \${_Msh_SHELL##*/} in
	(zsh*)	# Invoke zsh as sh from the get-go. Switching to emulation from within a script would be inadequate: this won't
	 	# remove common lowercase variable names as special -- e.g., "\$path" would still change "\$PATH" when used.
	 	# The '--emulate sh' cmdline option won't do either, as helper scripts invoked like '\$MSH_SHELL -c ...' would
	 	# find themselves in native zsh mode again. The only way is to use a 'sh' symlink for the duration of the script.
	 	user_path=\$PATH
	 	PATH=\${_Msh_DEFPATH}
	 	unset -v zshdir
	 	trap 'rm -rf "\${zshdir-}" &' 0	# BUG_TRAPEXIT compat
	 	for sig in INT PIPE TERM; do
	 		trap 'rm -rf "\${zshdir-}"; trap - '"\$sig"' 0; kill -s '"\$sig"' \$\$' "\$sig"
	 	done
	 	zshdir=\${XDG_RUNTIME_DIR:-\${TMPDIR:-/tmp}}/_Msh_zsh.\$\$.\$(date +%Y%m%d.%H%M%S).\${RANDOM:-0}
	 	mkdir -m700 "\$zshdir" || exit
	 	ln -s "\${_Msh_SHELL}" "\$zshdir/sh" || exit
	 	_Msh_SHELL=\$zshdir/sh
	 	PATH=\$user_path
	 	"\${_Msh_SHELL}" "\$@"	# no 'exec', or the trap won't run
	 	exit ;;
	(bash*)	# Avoid inheriting exported functions.
	 	exec "\${_Msh_SHELL}" -p "\$@" ;;
	( * )	# Default: just run.
	 	exec "\${_Msh_SHELL}" "\$@" ;;
	esac
	end_of_wrapper
}

# -------- main ---------

# Prepare shellquoted relative path for insertion in wrapper script.
not str empty $installroot && shellquote -P installroot_q=$installroot || unset -v installroot_q

# Do "static linking" of all cap tests.
link_cap_tests

# Install bundled programs, generating a wrapper script for each.
for script do
	str begin $script '/' || script=$PWD/$script	# must use absolute path for install_file()
	script_basename=${script##*/}
	shellquote script_basename_q=$script_basename
	install_file $script $opt_D$installroot/bin/$script_basename
	install_wrapper_script $script_basename $script_basename_q
done

# Lastly, generate README.
install_file - $opt_D$installroot/README.modernish <<-end_of_readme
$(
	{
		put "This directory contains "
		let "$# > 1" && put "the programs "
		while let "$# > 2"; do
			shellquote -f program=${1##*/}
			put "$program, "
			shift
		done
		if let "$# > 1"; then
			shellquote -f program=${1##*/}
			put "$program and "
			shift
		fi
		shellquote -f program=${1##*/}
		put "$program along with a stripped-down copy of modernish $MSH_VERSION, the portable shell" \
			"programming library that takes the 'hell' out of shell! This way of bundling allows" \
			"running modernish programs without installing the library system-wide.$CCn"
	} | fold -s -w 80
)

This bundled version of modernish should be considered as similar to compiled
object code. Interactive use is not supported, the documentation and the
regression test suite are missing, and all the comments are stripped out.

To get the source and try the complete version, head over to:
https://github.com/modernish/modernish#readme
To get this exact version ($MSH_VERSION), look under 'Releases'.

Modernish is Free software, available under the following licence.
Note that this licence is for modernish itself, NOT the bundled program$(let "$# > 1" && put 's').

----
Licence for modernish $MSH_VERSION

$(cat $MSH_PREFIX/LICENSE)
end_of_readme

# End. Return to install.sh.
