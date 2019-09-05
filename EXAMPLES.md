# Modernish code examples #

This file aims to demonstrate modernish by showing side-by-side comparisons
of plain POSIX shell script and modernish script.

For documentation, see [README.md](README.md).


## Git timestamp restorer ##

This script sets the timestamps on working directory files within a local Git
repository to the date of the last commit in which they were changed, so you
can use your regular `ls -l` to see when the files were last changed, `ls -lt`
to sort by last-modified, and so on. If you first change to a subdirectory of
the repo, it will only restore the timestamps down from that directory.

<table>
<tr><th align="left">Plain POSIX sh version</th><th>#</th><th align="left">Modernish version</th></tr>
<tr>
<td valign="top">

```sh
#! /bin/sh








git status >/dev/null || exit
if ! git diff-index --quiet HEAD; then
    echo 'Working dir not clean' >&2
    exit 1
fi

find . -name .git -prune \
-o -exec sh -c '
    # Ask Git for latest commit'\''s timestamp,
    # formatted for POSIX '\''touch -t'\''.
    timestamp=$(git log --format=%cd \
      --date=format:%Y%m%d%H%M.%S \
      -1 HEAD -- "$1") || exit
    [ -n "$timestamp" ] || exit

    set -x
    touch -t "$timestamp" "$1"
' dummy {} \;
```

</td>
<td valign="top">

```
1
2
3
4
5
6

7
8
9
10
11
12
13
14
15

16
17
18


19
20
21
22
23
24
25
```

</td>
<td valign="top">

```sh
#! /usr/bin/env modernish
#! use safe
#! use sys/cmd/harden
#! use var/loop
harden git
harden -e '>1' -f wd_is_clean \
    git diff-index --quiet HEAD
harden -pt touch

git status >/dev/null
wd_is_clean || exit 1 'Working dir not clean'



total=0
LOOP find repofile in . -name .git -prune \
-or -iterate; DO
    # Ask Git for latest commit's timestamp,
    # formatted for POSIX 'touch -t'.
    timestamp=$(git log --format=%cd \
      --date=format:%Y%m%d%H%M.%S \
      -1 HEAD -- $repofile)
    str empty $timestamp && continue

    # 'touch' is traced by 'harden -t'.
    touch -t $timestamp $repofile
    let "total+=1"
DONE
exit 0 "$total timestamps restored."
```

</td>
</tr>
</table>

### Discussion ###

This simple script demonstrates two main aspects of modernish:
command hardening, and the `find` loop. It also shows the safe
mode, how to write a portable-form script, and how to use modules.

* **Line 1:**
  The hashbang path of the modernish version indicates a
  [portable-form modernish script](README.md#user-content-two-basic-forms-of-a-modernish-program).
  The script is guaranteed to be executed by
  [a shell that passed modernish's fatal bug tests](README.md#user-content-supported-shells).
  By contrast, the `#!/bin/sh` hashbang path is not guaranteed to lead to any
  shell in particular; it could be an original Bourne shell without any modern
  POSIX features (like on Solaris 10), or pdksh which breaks the safe mode, or
  nothing at all. The `/usr/bin/env` utility path is a de-facto standard: not
  formally standardardised, but very portable in practice.
* **Line 2:**
  The [safe mode](README.md#user-content-use-safe) disables default
  splitting and globbing, none of which we need in this script. This makes
  unquoted variable expansions and command substitutions safe to use (lines
  18, 19, 22).
* **Lines 3, 5-7:**
  [Command hardening](README.md#user-content-use-syscmdharden)
  is optional; this script will work without, as the POSIX sh version does.
  However, it is highly recommended for securing and debugging your script. To
  demonstrate this, try introducing an argument error to the `git` command in
  the command substitution on lines 20-22 – for instance, change `--format=%cd`
  to `--format=@cd`, a format error in git. If you try this, you will see how a
  fatal error in a hardened `git` command will reliably cause the script to
  terminate at the exact point where the fatal error occurred, producing one
  error message showing the exact command that failed – even if it was executed
  in a subshell environment (the command substitution) which is normally not
  capable of exiting the main script. This makes debugging easy. Introducing
  the same typo in the POSIX sh version will not cause the script to terminate;
  instead, it continues, producing an error message for each file found. For a
  trivial script like this, this difference may not be very important, but for
  more complex scripts, conventional shell quickly becomes too difficult to
  debug, and the resulting inconsistent state may be dangerous to your data –
  whereas modernish with hardened commands remains just as easy to debug, and
  ensures faulty commands will not cause any damage. I make typos all the time,
  so this feature has saved me many times. Hardening will similarly terminate
  the script if the utility itself is not found, is killed by a signal, or
  somehow cannot be invoked – so it also keeps your script from continuing and
  potentially causing damage in case of system errors, such as out of memory, a
  hard disk fault, etc.
    * **Line 6:**
      This demonstrates a slightly more complex use case for command hardening.
      By default, `harden` considers any non-zero exit status to be a fatal
      error; the `harden git` command in line 5 hardens `git` like that.
      In specific cases where a non-zero exit status is valid, such as when
      checking if the current repo working directory is clean, it is helpful to
      harden the command under a separate name. The `-e '>1'` exit status
      expression tells `harden` that any exit status other than 0 or 1 is a
      fatal error. The `-f wd_is_clean` command causes this hardened command to
      be defined as a shell function named `wd_is_clean`. Extra command
      arguments to `git` given in the hardening definition are simply passed on
      as is. Thus we get a hardened, secured `wd_is_clean` command that will
      reliably terminate the script on encountering any unexpected condition.
    * **Line 7:**
      The `-p` option causes `harden` to search for the `touch` command in
      `$DEFPATH`, the system default path output by `getconf PATH` that
      guarantees finding
      [all standard POSIX utilities](http://shellhaters.org/)
      but nothing else. Using the `-p` option is recommended when hardening a
      standard utility; it increases security as it guarantees you get the
      system utility and not some other command by the same name.
      The `-t` option enables tracing for hardened commands; it pretty-prints a
      colourised trace showing the exact command executed, without all the
      extra noise produced by using `set -x` (`set -o xtrace`) in combination
      with a shell library.
* **Lines 4, 15, 23-24**:
  Robust processing of arbitrary file names (including whitespace, newlines,
  etc.) using POSIX `find` is possible; the left-side POSIX script shows how to
  do it. The only way is to launch an external command with `-exec`. If you'd
  like that external command to do anything slightly complicated, the typical
  POSIX idiom involves `-exec`ing a child `sh` that uses the `-c` option to run
  its own script from scratch, once per file name. That whole script needs to
  be one argument, properly quoted, followed by a dummy argument to set `$0`
  (the script name) in the child shell, followed by `{}` which is replaced by
  each file name and becomes the first positional parameter `$1` in the script,
  followed by a quoted semicolon that signals the end of the `-exec` primary to
  `find`. Disadvantages are evident. It is not possible to stop on error; if
  the child script exits due to an error, `find` will simply continue to the
  next anyway. A separate script that cannot access any of your main shell's
  variables or shell functions, or vice versa. And the child script is executed
  by whatever `sh` command is found first in your user's `$PATH`, which is not
  necessarily a known entity. To avoid these problems, many shell scripts
  instead parse `find` output in a `for` loop with a command substitution,
  using field splitting in
  [extremely unsafe ways](https://dwheeler.com/essays/filenames-in-shell.html).    
  **By contrast,** modernish can use
  [`LOOP find`](README.md#user-content-the-find-loop).
  This loop type of the generic
  [modernish loop construct](README.md#user-content-use-varloop)
  integrates the `find` utility into the shell so it can be used in the
  same way you'd use a regular `for` loop. Arbitrary file names are processed
  correctly by default and stored in a variable, as with `for`. Further
  processing is done in the loop body which is part of your main script, so it
  will use your shell settings (e.g. safe mode), functions, variables, and
  whatnot. To demonstrate this, we add a little feature to the modernish
  version: count the total number of files processed, using a variable that
  survives the loop like any other.
* **Line 9:** Since `git` is hardened, an `|| exit` would be superfluous.
* **Lines 10, 25:**
  The [enhanced exit](README.md#user-content-enhanced-exit)
  command allows specifying an error or informative message.
  This removes the need for a separate `echo`, which makes a more
  concise coding style possible when checking for error conditions.
* **Line 19**: The modernish replacement for `test`/`[` is safe for leaving
  variables unquoted, unlike `[ -n ... ]` or `test -n ...`. The thing here is
  that an unquoted variable is removed if empty, so with the test command, you
  effectively end up with `[ -n ]` or `test -n`. Both of these yield a false
  positive, as this is taken as an alternative syntax for testing if a string
  is empty, with `-n` itself (which is non-empty) being the string tested.
  By contrast, the operators to the
  [`str` command](README.md#user-content-testing-numbers-strings-and-files)
  deal correctly with empty removal and return the expected exit status.
  Like all other modernish functions, the replacements for `test`/`[` are also
  hardened with paranoid argument and bounds checking, reliably terminating the
  script if a fatal mistake is encountered (such as excess arguments due to
  unexpected field splitting or globbing).
* **Line 23**: With modernish, the
  [`let` arithmetic command](README.md#user-content-the-arithmetic-command-let)
  is made available on all supported POSIX shells. The `++` and `--` unary
  operators are *not* supported by all shells, so to increase a variable's
  value, we use `+=1` instead.


## TODO ##

More side-by-side example scripts with discussion to follow.
