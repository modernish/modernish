#! /usr/bin/env modernish
#! use safe
#! use sys/cmd/harden
#! use sys/cmd/procsubst
#! use var/shellquote
harden -tp cd
harden -t gzip
harden -tp head
harden -tPp ls
harden -tp pax

putln "====" "We can diff the output of two commands!"
diff -u $(% ls) $(% ls -a)

putln "====" "We can 'while read' without a here-doc!"
while read -r foo; do
	putln "${CCt}*** [ $foo ] ***"
done <`% ls $MSH_PREFIX/share/doc/modernish` | head

putln "====" "We can do output command substitutions!"
archive=/tmp/modernish-doc-$MSH_VERSION.tgz
(cd $MSH_PREFIX; pax -wf $(% -o eval 'gzip -c >|$archive') $MSH_PREFIX/share/doc/modernish)
putln "compressed archive saved in $archive"

shellquote tmpdir=${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}
shellquote -f lstmp="ls $tmpdir"
putln "====" "Testing that die() does not leave junk FIFOs (_Msh_FIFO*)." "Do $lstmp to check."
while read -r foo; do
	putln "${CCt}*** [ $foo ] ***"
done <$(% str eq 1 2 3) | head
        # ^^^^^^^^^^^^ too many arguments should kill the program

putln "BAD! Should never get here."
