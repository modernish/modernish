# Modernish code examples #

*This file is under construction.*

This file aims to demonstrate modernish by showing side-by-side comparisons
of plain POSIX shell script and modernish script.

For documentation, see [README.md](https://github.com/modernish/modernish/blob/master/README.md).

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
    echo 'Working directory not clean.' >&2
    exit 1
fi

find . -name .git -prune \
-o -exec sh -c '
    # Ask Git for latest commit'\''s timestamp,
    # formatted for POSIX '\''touch -t'\''.
    timestamp=$(git log --format=%cd \
      --date=format:%Y%m%d%H%M.%S \
      -1 HEAD -- "$1") || exit
    [ -z "$timestamp" ] && exit

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
if not wd_is_clean; then
    exit 1 'Working directory not clean.'
fi

total=0
LOOP find repofile in . -name .git \
-prune -or -iterate; DO
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

* **Lines 3, 5-7:**
  [Command hardening](https://github.com/modernish/modernish#user-content-use-syscmdharden)
  is optional; this script will work without, as the POSIX sh version does.
  However, it is highly recommended for securing and debugging your script. To
  demonstrate this, try introducing an argument error to the `git` command in
  the command substitution on lines 20-22 – for instance, change `--format=%cd`
  to `--format=@cd`, a format error in git. Command substitutions are executed
  in subshell environments, but if you try this, you will see how a fatal error
  in a hardened `git` command will reliably cause the script to terminate at
  the exact point where the fatal error occurred, producing one error message
  showing the exact command that failed. This makes debugging easy. Introducing
  the same typo in the POSIX sh version will not cause the script to terminate;
  instead, it continues, producing an error message for each file found. For a
  trivial script like this, this difference may not be very important, but for
  more complex scripts, conventional shell quickly becomes too difficult to
  debug, and the resulting inconsistent state may be dangerous to your data –
  whereas modernish with hardened commands remains just as easy to debug, and
  ensures faulty commands will not cause any damage. I make typos all the time,
  so this feature has saved me many times. Hardening will similarly terminate
  the script if the `git` executable itself is not found, is killed by a
  signal, or somehow cannot be invoked – so it also keeps your script from
  continuing and causing damage in case of system errors.
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
* TODO: complete the discussion
