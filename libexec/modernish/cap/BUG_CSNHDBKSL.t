#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_CSNHDBKSL (Command Substitution Non-expanding Here-Document BacKSLash):
# Backslashes within non-expanding here-documents within command substitutions
# are incorrectly expanded to perform newline joining, as opposed to left intact.
# Bug found on bash up to 4.4, and pdksh (not mksh).
# Ref.: http://lists.gnu.org/archive/html/bug-bash/2017-02/msg00023.html
#       http://unix.stackexchange.com/q/340923/73093
#       http://unix.stackexchange.com/q/340718/73093
# Bug found and initial test made by Michael Homer.

_Msh_test=$(command umask 077; PATH=$DEFPATH command cat <<'EOT'
abc
def \
ghi
jkl
EOT
)
case ${_Msh_test} in
# expected result:
# "abc${CCn}def \\${CCn}ghi${CCn}jkl"
( "abc${CCn}def ghi${CCn}jkl" )
	return 0 ;;  # bug
( * )	return 1 ;;
esac
