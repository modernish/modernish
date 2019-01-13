#! test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

isTestDir=$testdir/is
mkdir $isTestDir

# 'ln' was hardened in run.sh
ln -s $MSH_SHELL $isTestDir/symlink
ln -s /dev/null $isTestDir/symlink2

TEST title='is older: nonexistent 1st file'
	is older /dev/null/nonexistent $MSH_SHELL &&
	is -L older /dev/null/nonexistent $MSH_SHELL &&
	is older /dev/null/nonexistent $isTestDir/symlink &&
	is -L older /dev/null/nonexistent $isTestDir/symlink
ENDT

TEST title='is older: nonexistent 2nd file'
	! is older $MSH_SHELL /dev/null/nonexistent &&
	! is -L older $MSH_SHELL /dev/null/nonexistent &&
	! is older $isTestDir/symlink /dev/null/nonexistent &&
	! is -L older $isTestDir/symlink /dev/null/nonexistent
ENDT

TEST title='is older: both files nonexistent'
	! is older /dev/null/no1 /dev/null/no2 &&
	! is -L older /dev/null/no1 /dev/null/no2
ENDT

TEST title='is older: both files exist'
	is older $MSH_SHELL $isTestDir &&
	is -L older $MSH_SHELL $isTestDir &&
	is older $MSH_SHELL $isTestDir/symlink &&
	! is -L older $MSH_SHELL $isTestDir/symlink
ENDT

TEST title='is newer: nonexistent 1st file'
	! is newer /dev/null/nonexistent $MSH_SHELL &&
	! is -L newer /dev/null/nonexistent $MSH_SHELL &&
	! is newer /dev/null/nonexistent $isTestDir/symlink &&
	! is -L newer /dev/null/nonexistent $isTestDir/symlink
ENDT

TEST title='is newer: nonexistent 2nd file'
	is newer $MSH_SHELL /dev/null/nonexistent &&
	is -L newer $MSH_SHELL /dev/null/nonexistent &&
	is newer $isTestDir/symlink /dev/null/nonexistent &&
	is -L newer $isTestDir/symlink /dev/null/nonexistent
ENDT

TEST title='is newer: both files nonexistent'
	! is newer /dev/null/no1 /dev/null/no2 &&
	! is -L newer /dev/null/no1 /dev/null/no2
ENDT

TEST title='is newer: both files exist'
	is newer $isTestDir $MSH_SHELL &&
	is -L newer $isTestDir $MSH_SHELL &&
	is newer $isTestDir/symlink $MSH_SHELL &&
	! is -L newer $isTestDir/symlink $MSH_SHELL
ENDT


TEST title="is samefile: nonexistent 1st file"
	! is samefile /dev/null/nonexistent $MSH_SHELL &&
	! is -L samefile /dev/null/nonexistent $MSH_SHELL &&
	! is samefile /dev/null/nonexistent $isTestDir/symlink &&
	! is -L samefile /dev/null/nonexistent $isTestDir/symlink
ENDT

TEST title="is samefile: nonexistent 2nd file"
	! is samefile $MSH_SHELL /dev/null/nonexistent &&
	! is -L samefile $MSH_SHELL /dev/null/nonexistent &&
	! is samefile $isTestDir/symlink /dev/null/nonexistent &&
	! is -L samefile $isTestDir/symlink /dev/null/nonexistent
ENDT

TEST title="is samefile: both files nonexistent"
	! is samefile /dev/null/no1 /dev/null/no2 &&
	! is -L samefile /dev/null/no1 /dev/null/no2
ENDT

TEST title="is samefile: both files exist"
	is samefile /dev/tty /dev/tty &&
	is -L samefile $MSH_SHELL $isTestDir/symlink
ENDT

TEST title="is onsamefs: nonexistent 1st file"
	! is onsamefs /dev/null/nonexistent $MSH_SHELL &&
	! is -L onsamefs /dev/null/nonexistent $MSH_SHELL &&
	! is onsamefs /dev/null/nonexistent $isTestDir/symlink &&
	! is -L onsamefs /dev/null/nonexistent $isTestDir/symlink
ENDT

TEST title="is onsamefs: nonexistent 2nd file"
	! is onsamefs $MSH_SHELL /dev/null/nonexistent &&
	! is -L onsamefs $MSH_SHELL /dev/null/nonexistent &&
	! is onsamefs $isTestDir/symlink /dev/null/nonexistent &&
	! is -L onsamefs $isTestDir/symlink /dev/null/nonexistent
ENDT

TEST title="is onsamefs: both files nonexistent"
	! is onsamefs /dev/null/no1 /dev/null/no2 &&
	! is -L onsamefs /dev/null/no1 /dev/null/no2
ENDT

TEST title="is onsamefs: both files exist"
	is onsamefs /dev/tty /dev/null &&
	is onsamefs $isTestDir $isTestDir/symlink &&
	is -L onsamefs $MSH_SHELL $isTestDir/symlink
ENDT
