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
	}" ${opt_D}$installroot/bin/modernish >| $tmpdir/patched_bin_modernish || die

	# 'sed' doesn't even give an error message or a nonzero status if the 'r'
	# command fails to read the file, so we have to check the results.
	num_captests_ok=$(grep -c '^_Msh_CAP_.*() {$' $tmpdir/patched_bin_modernish)
	if not eq num_captests_ok num_captests; then
		putln '' "  --  FAIL"
		exit 3 "Static linking FAILED: $num_captests processed, $num_captests_ok linked"
	fi

	cat $tmpdir/patched_bin_modernish >| ${opt_D}$installroot/bin/modernish || die
	put_wrap "  --  done ($num_captests)."
	putln; column_pos=0
	rm -r ${opt_D}$installroot/lib/modernish/cap <&-
}

# Generate and install a wrapper script that runs a bundled program with modernish.
# usage: install_wrapper_script SCRIPTBASENAME SHELLQUOTED_SCRIPTBASENAME
install_wrapper_script() {
	install_file - $opt_D/$1 <<-end_of_wrapper
	#! /bin/sh -fCu
	# Wrapper script to run $2 with bundled modernish

	# Find my own absolute and physical directory path.
	unset -v CDPATH
	case \$0 in
	( */* )	MSH_PREFIX=\${0%/*} ;;
	( * )	MSH_PREFIX=. ;;
	esac
	case \$MSH_PREFIX in
	( */* | [!+-]* | [+-]*[!0123456789]* )
	 	MSH_PREFIX=\$(cd -- "\$MSH_PREFIX" && pwd -P && echo X) ;;
	( * )	MSH_PREFIX=\$(cd "./\$MSH_PREFIX" && pwd -P && echo X) ;;
	esac || exit
	export MSH_PREFIX="\${MSH_PREFIX%?X}"${installroot_q:+$installroot_q}

	# Get the system's default path.
	. "\$MSH_PREFIX/lib/modernish/aux/defpath.sh" || exit
	export DEFPATH

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
	case \${MSH_SHELL##*/} in
	(zsh*)	# Invoke zsh as sh from the get-go. Switching to emulation from within a script would be inadequate: this won't
	 	# remove common lowercase variable names as special -- e.g., "\$path" would still change "\$PATH" when used.
	 	# The '--emulate sh' cmdline option won't do either, as helper scripts invoked like '\$MSH_SHELL -c ...' would
	 	# find themselves in native zsh mode again. The only way is to use a 'sh' symlink for the duration of the script.
	 	user_path=\$PATH
	 	PATH=\$DEFPATH
	 	unset -v zshdir
	 	trap 'rm -rf "\${zshdir-}" & trap - 0' 0	# BUG_TRAPEXIT compat
	 	for sig in INT PIPE TERM; do
	 		trap 'rm -rf "\${zshdir-}" & trap - '"\$sig"' 0; kill -s '"\$sig"' \$\$' "\$sig"
	 	done
	 	if ! { zshdir=\$(mktemp -d /tmp/_Msh_zsh.XXXXXXXXXX 2>/dev/null) && test -d "\$zshdir"; }; then
	 		zshdir=/tmp/_Msh_zsh.\$\$.\$(date +%Y%m%d.%H%M%S).\${RANDOM:-0}
	 		mkdir -m700 "\$zshdir" || exit
	 	fi
	 	ln -s "\$MSH_SHELL" "\$zshdir/sh" || exit
	 	MSH_SHELL=\$zshdir/sh
	 	PATH=\$user_path
	 	"\$MSH_SHELL" "\$@"	# no 'exec', or the trap won't run
	 	exit ;;
	(bash*)	# Avoid inheriting exported functions.
	 	exec "\$MSH_SHELL" -p "\$@" ;;
	( * )	# Default: just run.
	 	exec "\$MSH_SHELL" "\$@" ;;
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
	script_basename=${script##*/}
	shellquote -f script_basename_q=$script_basename
	# Install a bundled script. Temporarily unset -B option to avoid stripping comments and checking for a patch.
	(
		unset -v opt_B
		install_file $script $opt_D$installroot/bin/$script_basename
	) || exit
	# Install its wrapper.
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
https://github.com/modernish/modernish/tree/0.16#readme
To get this exact version ($MSH_VERSION), look under 'Releases'.

Modernish is Free software, available under the following licence.
Note that this licence is for modernish itself, NOT the bundled program$(let "$# > 1" && put 's').

----
Licence for modernish $MSH_VERSION

$(cat LICENSE)
end_of_readme

# End. Return to install.sh.
