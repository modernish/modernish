
# --- General file tests. ---

# Test if file exists and is not an invalid symlink.
f_exists() {
	test $# -eq 1 || _msh_dienarg f_exists $# 1
	test -e "$1"
}

# Test if file exists, is not an invalid symlink, and is not empty.
f_isnotempty() {
	test $# -eq 1 || _msh_dienarg f_isnotempty $# 1
	test -s "$1"
}

# Test if file descriptor is open and associated with a terminal.
#	Note: POSIX specifies that file descriptors can be 0 to minimum 19,
#	but most shells only support file descriptors between 0 and 9.
fd_isonterm() {
	test $# -eq 1 || _msh_dienarg fd_isonterm $# 1
	case "$1" in
	( 0|1|2|3|4|5|6|7|8|9 )
		test -t $1 ;;
	( * )
		die "isonterm: invalid file descriptor: $1" ;;
	esac
}

# --- File permission tests. ---
# Note: These automatically resolve symlinks.

# Test if this program can read, write or execute a file.
f_canread() {
	test $# -eq 1 || _msh_dienarg f_canread $# 1
	test -r "$1"
}
f_canwrite() {
	test $# -eq 1 || _msh_dienarg f_canwrite $# 1
	test -w "$1"
}
f_canexec() {
	test $# -eq 1 || _msh_dienarg f_canexec $# 1
	test -x "$1"
}
	
# Test if file has user or group ID bits set.
f_issetuid() {
	test $# -eq 1 || _msh_dienarg f_issetgid $# 1
	test -u "$1"
}
f_issetgid() {
	test $# -eq 1 || _msh_dienarg f_issetgid $# 1
	test -g "$1"
}

# --- File type tests. ---
# Note: These do *not* resolve symlinks unless the _L variant is used.
# This is to promote security and discourage allowing symlink attacks.

# symlink
f_issym() {
	test $# -ge 1 || _msh_dienarg f_issym $# 'at least 1'
	for _msh_v; do
		test -L "$_msh_v" || return
	done
}

# block special
f_isblk() {
	test $# -ge 1 || _msh_dienarg f_isblk $# 'at least 1'
	for _msh_v; do
		test ! -L "$_msh_v" && test -b "$_msh_v" || return
	done
}
f_isblk_L() {
	test $# -ge 1 || _msh_dienarg f_isblk_L $# 'at least 1'
	for _msh_v; do
		test -b "$_msh_v" || return
	done
}

# character special
f_ischr() {
	test $# -ge 1 || _msh_dienarg f_ischr $# 'at least 1'
	for _msh_v; do
		test ! -L "$_msh_v" && test -c "$_msh_v" || return
	done
}
f_ischr_L() {
	test $# -ge 1 || _msh_dienarg f_ischr_L $# 'at least 1'
	for _msh_v; do
		test -c "$_msh_v" || return
	done
}

# directory
f_isdir() {
	test $# -ge 1 || _msh_dienarg f_isdir $# 'at least 1'
	for _msh_v; do
		test ! -L "$_msh_v" && test -d "$_msh_v" || return
	done
}
f_isdir_L() {
	test $# -ge 1 || _msh_dienarg f_isdir_L $# 'at least 1'
	for _msh_v; do
		test -d "$_msh_v" || return
	done
}

# regular file
f_isreg() {
	test $# -ge 1 || _msh_dienarg f_isreg $# 'at least 1'
	for _msh_v; do
		test ! -L "$_msh_v" && test -f "$_msh_v" || return
	done
}
f_isreg_L() {
	test $# -ge 1 || _msh_dienarg f_isreg_L $# 'at least 1'
	for _msh_v; do
		test -f "$_msh_v" || return
	done
}

# FIFO (named pipe)
f_isfifo() {
	test $# -ge 1 || _msh_dienarg f_isfifo $# 'at least 1'
	for _msh_v; do
		test ! -L "$_msh_v" && test -p "$_msh_v" || return
	done
}
f_isfifo_L() {
	test $# -ge 1 || _msh_dienarg f_isfifo_L $# 'at least 1'
	for _msh_v; do
		test -p "$_msh_v" || return
	done
}

# socket
f_issock() {
	test $# -ge 1 || _msh_dienarg f_issock $# 'at least 1'
	for _msh_v; do
		test ! -L "$_msh_v" && test -S "$_msh_v" || return
	done
}
f_issock_L() {
	test $# -ge 1 || _msh_dienarg f_issock_L $# 'at least 1'
	for _msh_v; do
		test -S "$_msh_v" || return
	done
}

