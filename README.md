# modernish: a shell moderniser library #

modernish is an ambitious, as-yet experimental, cross-platform POSIX shell
feature detection and language extension library. It aims to extend the
shell language with extensive
[feature testing](#user-content-feature-testing)
and language enhancements,
using the power of aliases and functions to extend the shell language
using the shell language itself.

The name is a pun on Modernizr, the JavaScript feature testing library, -sh,
the common suffix for UNIX shell names, and -ish, still not quite a modern
programming language but perhaps a little closer. jQuery is another source
of general inspiration; like it, modernish adds a considerable feature set
by using the power of the language it's implemented in to extend/transcend
that same language.

That said, the aim of modernish is to build a better shell language, and not
to make the shell language into something it's not. Its feature set is aimed
at solving specific and commonly experienced deficits and annoyances of the
shell language, and not at adding/faking things that are foreign to it, such
as object orientation or functional programming. (However, since modernish
is modular, nothing stops anyone from adding a module attempting to
implement these things.)

The library builds on pure POSIX 2013 Edition (including full C-style shell
arithmetics with assignment, comparison and conditional expressions), so it
should run on any POSIX-compliant shell and operating system. But it does
not shy away from using non-standard extensions where available to enhance
performance or robustness.

Some example programs are in `share/doc/modernish/examples`.

Modernish also comes with a suite of regression tests to detect bugs in
modernish itself. See [Appendix B](#user-content-appendix-b).


## Table of contents ##

  * [Getting started](#user-content-getting-started)
  * [Two basic forms of a modernish program](#user-content-two-basic-forms-of-a-modernish-program)
    * [Important notes regarding the system locale](#user-content-important-notes-regarding-the-system-locale)
  * [Interactive use](#user-content-interactive-use)
  * [Non-interactive command line use](#user-content-non-interactive-command-line-use)
    * [Non-interactive usage examples](#user-content-non-interactive-usage-examples)
  * [Internal namespace](#user-content-internal-namespace)
  * [Feature testing](#user-content-feature-testing)
  * [Modernish system constants](#user-content-modernish-system-constants)
    * [Control character, whitespace and shell-safe character constants](#user-content-control-character-whitespace-and-shell-safe-character-constants)
  * [Legibility aliases](#user-content-legibility-aliases)
  * [Enhanced exit](#user-content-enhanced-exit)
  * [Reliable emergency halt](#user-content-reliable-emergency-halt)
  * [Low-level shell utilities](#user-content-low-level-shell-utilities)
  * [Quoting strings for subsequent parsing by the shell](#user-content-quoting-strings-for-subsequent-parsing-by-the-shell)
  * [The stack](#user-content-the-stack)
    * [The shell options stack](#user-content-the-shell-options-stack)
    * [The trap stack](#user-content-the-trap-stack)
      * [Trap stack compatibility considerations](#user-content-trap-stack-compatibility-considerations)
    * [Positional parameters stack](#user-content-positional-parameters-stack)
    * [Stack query and maintenance functions](#user-content-stack-query-and-maintenance-functions)
  * [Hardening: emergency halt on error](#user-content-hardening-emergency-halt-on-error)
    * [Important note on variable assignments](#user-content-important-note-on-variable-assignments)
    * [Hardening while allowing for broken pipes](#user-content-hardening-while-allowing-for-broken-pipes)
    * [Tracing the execution of hardened commands](#user-content-tracing-the-execution-of-hardened-commands)
  * [Simple tracing of commands](#user-content-simple-tracing-of-commands)
  * [External commands without full path](#user-content-external-commands-without-full-path)
  * [Outputting strings](#user-content-outputting-strings)
  * [Enhanced dot scripts](#user-content-enhanced-dot-scripts)
  * [Testing numbers, strings and files](#user-content-testing-numbers-strings-and-files)
    * [Integer number arithmetic tests and operations](#user-content-integer-number-arithmetic-tests-and-operations)
    * [String tests](#user-content-string-tests)
    * [File type tests](#user-content-file-type-tests)
    * [File comparison tests](#user-content-file-comparison-tests)
    * [File status tests](#user-content-file-status-tests)
    * [I/O tests](#user-content-io-tests)
    * [File permission tests](#user-content-file-permission-tests)
  * [Basic string operations](#user-content-basic-string-operations)
    * [toupper/tolower](#user-content-touppertolower)
  * [Basic system utilities](#user-content-basic-system-utilities)
  * [Modules](#user-content-modules)
    * [use safe](#user-content-use-safe)
    * [use var/arith](#user-content-use-vararith)
      * [Arithmetic operator shortcuts](#user-content-arithmetic-operator-shortcuts)
      * [Arithmetic comparison shortcuts](#user-content-arithmetic-comparison-shortcuts)
    * [use var/mapr](#user-content-use-varmapr)
      * [Differences from `mapfile`](#user-content-differences-from-mapfile)
    * [use var/readf](#user-content-use-varreadf)
    * [use var/setlocal](#user-content-use-varsetlocal)
    * [use var/string](#user-content-use-varstring)
    * [use sys/base](#user-content-use-sysbase)
      * [use sys/base/readlink](#user-content-use-sysbasereadlink)
      * [use sys/base/which](#user-content-use-sysbasewhich)
      * [use sys/base/mktemp](#user-content-use-sysbasemktemp)
      * [use sys/base/seq](#user-content-use-sysbaseseq)
      * [use sys/base/rev](#user-content-use-sysbaserev)
    * [use sys/dir](#user-content-use-sysdir)
      * [use sys/dir/traverse](#user-content-use-sysdirtraverse)
      * [use sys/dir/countfiles](#user-content-use-sysdircountfiles)
    * [use sys/term](#user-content-use-systerm)
      * [use sys/term/readkey](#user-content-use-systermreadkey)
    * [use opts/parsergen](#user-content-use-optsparsergen)
    * [use loop/cfor](#user-content-use-loopcfor)
    * [use loop/sfor](#user-content-use-loopsfor)
    * [use loop/with](#user-content-use-loopwith)
    * [use loop/select](#user-content-use-loopselect)
  * [Appendix A](#user-content-appendix-a)
    * [Capabilities](#user-content-capabilities)
    * [Quirks](#user-content-quirks)
    * [Bugs](#user-content-bugs)
    * [Warning IDs](#user-content-warning-ids)
  * [Appendix B](#user-content-appendix-b)
    * [Difference between bug/quirk/feature tests and regression tests](#user-content-difference-between-bugquirkfeature-tests-and-regression-tests)
    * [Testing modernish on all your shells](#user-content-testing-modernish-on-all-your-shells)


## Getting started ##

Run `install.sh` and follow instructions, choosing your preferred shell
and install location. After successful installation you can run modernish
shell scripts and write your own. Run `uninstall.sh` to remove modernish.

Both the install and uninstall scripts are interactive by default, but
support fully automated (non-interactive) operation as well. Command
line options are as follows:

`install.sh` [ `-n` ] [ `-s` *shell* ] [ `-f` ] [ `-d` *installroot* ] [ `-D` *prefix* ]

* `-n`: non-interactive operation
* `-s`: specify default shell to execute modernish
* `-f`: force unconditional installation on specified shell
* `-d`: specify root directory for installation
* `-D`: extra destination directory prefix (for packagers)

`uninstall.sh` [ `-n` ] [ `-f` ] [ `-d` *installroot* ]

* `-n`: non-interactive operation
* `-f`: delete */modernish directories even if files left
* `-d`: specify root directory of modernish installation to uninstall


## Two basic forms of a modernish program ##

The **simplest** way to write a modernish program is to source modernish as a
dot script. For example, if you write for bash:

    #! /bin/bash
    . modernish
    use safe
    use sys/base
    ...your program starts here...

The modernish 'use' command load modules with optional functionality. `safe` is
a special module that introduces a new and safer way of shell programming, with
field splitting (word splitting) and pathname expansion (globbing) disabled by
default. The `sys/base` module contains modernish versions of certain basic but
non-standardised utilities (e.g. `readlink`, `mktemp`, `which`), guaranteeing
that modernish programs all have a known version at their disposal. There are
many other modules as well. See below for more information.

The above method makes the program dependent on one particular shell (in this
case, bash). So it is okay to mix and match functionality specific to that
particular shell with modernish functionality.

The **most portable** way to write a modernish program is to use the special
generic hashbang path for modernish programs. For example:

    #! /usr/bin/env modernish
    #! use safe
    #! use sys/base
    ...your program begins here...

A program in this form is executed by whatever shell the user who installed
modernish on the local system chose as the default shell. Since you as the
programmer can't know what shell this is (other than the fact that it passed
some rigorous POSIX compliance testing executed by modernish), a program in
this form *must be strictly POSIX compliant* -- except, of course, that it
should also make full use of the rich functionality offered by modernish.

Note that modules are loaded in a different way: the `use` commands are part of
hashbang comment (starting with `#!` like the initial hashbang path). Only such
lines that *immediately* follow the initial hashbang path are evaluated; even
an empty line in between causes the rest to be ignored.

### Important notes regarding the system locale ###
* modernish, like most shells, fully supports two locales: POSIX (a.k.a.
  C, a.k.a. ASCII) and Unicode's UTF-8. It will work in others, but things
  like converting to upper/lower case, and matching single characters in
  patterns, are not guaranteed.    
  *Caveat:* some shells or operating systems have bugs that prevent (or lack
  features required for) full locale support. If portability is a concern,
  check for `thisshellhas BUG_MULTIBYTE` or `thisshellhas BUG_NOCHCLASS`
  where needed. See Appendix A under [Bugs](#user-content-bugs).
* Scripts/programs should *not* change the locale (`LC_*` or `LANG`) after
  initialising modernish. Doing this might break various functions, as
  modernish sets specific versions depending on your OS, shell and locale.
  (Temporarily changing the locale is fine as long as you don't use
  modernish features that depend on it -- for example, setting a specific
  locale just for an external command. However, if you use `harden()`, see
  the [important note](#user-content-important-note-on-variable-assignments)
  in its documentation below!)

## Interactive use ##

Modernish is primarily designed to enhance shell programs/scripts, but also
offers features for use in interactive shells. For instance, the new `with`
loop construct from the `loop/with` module can be quite practical to repeat
an action x times, and the `safe` module on interactive shells provides
convenience functions for manipulating, saving and restoring the state of
field splitting and globbing.

To use modernish on your favourite interactive shell, you have to add it to
your `.profile`, `.bashrc` or similar init file.

**Important:** Upon initialising, modernish adapts itself to
other settings, such as the locale. It also removes certain aliases that
may keep modernish from initialising properly. So you have to organise your
`.profile` or similar file in the following order:

* *first*, define general system settings (`PATH`, locale, etc.);
* *then*, `. modernish` and `use` any modules you want;
* *then* define anything that may depend on modernish, and set your aliases.

## Non-interactive command line use ##

After installation, the `modernish` command can be invoked as if it were a
shell, with the standard command line options from other shells (such as
`-c` to specify a command or script directly on the command line), plus some
enhancements. The effect is that the shell chosen at installation time will
be run enhanced with modernish functionality. It is not possible to use
modernish as an interactive shell in this way.

Usage:

1. `modernish` [ `--use=`*module* | *option* ... ]
   [ *scriptfile* ] [ *arguments* ]
2. `modernish` [ `--use=`*module* | *option* ... ]
   `-c` [ *script* [ *me-name* [ *arguments* ] ] ]
3. `modernish --test`
4. `modernish --version`

In the first form, the `--use` long-form option preloads any given modernish
[modules](#user-content-modules), any given short or long-form shell *option*s
are set or unset (the syntax is identical to that of POSIX shells and the
[shell options](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_25_03)
supported depend on the shell executing modernish), and then *scriptfile* is
loaded and executed with any *arguments* assigned to the positional parameters.

The *module* argument to each specified `--use` option is split using
standard shell field splitting. The first field is the module name and any
further fields become arguments to that module's initialisation routine.

Using the shell option `-e` or `-o errexit` is an error, because modernish
[does not support it](#user-content-hardening-emergency-halt-on-error) and
would break. If the shell option `-x` or `-o xtrace` is given, modernish sets
the `PS4` prompt to a useful value that traces the line number and exit status,
as well as the current file and function names if the shell is capable of this.

In the second form, after pre-loading any *module*s and setting any shell
*option*s as in the first form, `-c` executes the specified modernish
*script*, optionally with the *me-name* assigned to `$ME` and the
*arguments* assigned to the positional parameters. This is identical to the
`-c` option on POSIX shells, except that the *me-name* is assigned to `$ME`
and not `$0` (because POSIX shells do not allow changing `$0`).

The `--test` option runs the regression test suite and exits. This verifies
that the modernish installation is functioning correctly.
See [Appendix B](#user-content-appendix-b) for more information.

The `--version` option outputs the version of modernish and exits.

### Non-interactive usage examples ###

* Count to 10 using [loop/with](#user-content-use-loopwith):    
  `modernish --use=loop/with -c 'with i=1 to 10; do putln "$i"; done'`
* Run a [portable-form](#user-content-two-basic-forms-of-a-modernish-program)
  modernish program using zsh and enhanced-prompt xtrace:    
  `zsh /usr/local/bin/modernish -o xtrace /path/to/program.sh`


## Internal namespace ##

Function-local variables are not supported by the standard POSIX shell; only
global variables are provided for. Modernish needs a way to store its
internal state without interfering with the program using it. So most of the
modernish functionality uses an internal namespace `_Msh_*` for variables,
functions and aliases. All these names may change at any time without
notice. *Any names starting with `_Msh_` should be considered sacrosanct and
untouchable; modernish programs should never directly use them in any way.*
Of course this is not enforceable, but names starting with `_Msh_` should be
uncommon enough that no unintentional conflict is likely to occur.


## Feature testing ##

Modernish includes a battery of shell bug, quirk and feature tests, each of
which is given a special ID.
See [Appendix A](#user-content-appendix-a) below for a list of shell
capabilities, quirks and bugs that modernish currently tests for,
as well as further general information on the feature testing framework.

`thisshellhas` is the central function of the modernish feature testing
framework. It not only tests for the presence of modernish shell
capabilities/quirks/bugs on the current shell, but can also test for the
presence of specific shell built-in commands, shell reserved words (a.k.a.
keywords), shell options (short or long form), and signals.

Modernish itself extensively uses feature testing to adapt itself to the
shell it's running on. This is how it works around shell bugs and takes
advantage of efficient features not all shells have. But any script using
the library can do this in the same way, with the help of this function.

For those tests that have no standardised way of performing them,
`thisshellhas` knows the shell-specific methods on all supported shells and
automatically initialises the correct version for the current shell.

Test results are cached in memory, so repeated checks using `thisshellhas`
are efficient and there is no need to avoid calling it to optimise
performance.

Usage:

`thisshellhas` [ `--cache` | `--show` ] *item* [ *item* ... ]

* If *item* contains only ASCII capital letters A-Z, digits 0-9 or `_`,
  return the result status of the associated modernish
  [feature, quirk or bug test](#user-content-appendix-a).
* If *item* is an ASCII all-lowercase word, check if it's a shell reserved
  word or built-in command on the current shell.
* If *item* starts with `--rw=` or `--kw=`, check if the identifier
  immediately following these characters is a shell reserved word
  (a.k.a. shell keyword).
* If *item* starts with `--bi=`, similarly check for a shell built-in command.
* If *item* starts with `--sig=`, check if the shell knows about a signal
  (usable by `kill`, `trap`, etc.) by the name or number following the `=`.
  If a number \> 128 is given, the remainder of its division by 128 is checked.
  If the signal is found, its canonicalised signal name is left in the
  `REPLY` variable, otherwise `REPLY` is unset. (If multiple `--sig=` items
  are given and all are found, `REPLY` contains only the last one.)
* If *item* is `-o` followed by a separate word, check if this shell has a
  long-form shell option by that name.
* If *item* is any other letter or digit preceded by a single `-`, check if
  this shell has a short-form shell option by that character.
* The `--cache` option runs all external modernish bug/quirk/feature tests
  that have not yet been run, causing the cache to be complete.
* The `--show` option performs a `--cache` and then outputs all the IDs of
  positive results, one per line.

`thisshellhas` continues to process *item*s until one of them produces a
negative result or is found invalid, at which point any further *item*s are
ignored. So the function only returns successfully if all the *item*s
specified were found on the current shell. (To check if either one *item* or
another is present, use separate `thisshellhas` invocations separated by the
`||` shell operator.)

Exit status: 0 if this shell has all the *items* in question; 1 if not; 2 if
an *item* was encountered that is not recognised as a valid identifier.

**Note:** The tests for the presence of reserved words, built-in commands,
shell options, and signals are different from feature/quirk/bug tests in an
important way: they only check if an item by that name exists on this shell,
and don't verify that it does the same thing as on another shell.


## Modernish system constants ##

Modernish provides certain constants (read-only variables) to make life easier.
These include:

* `$MSH_VERSION`: The version of modernish.
* `$MSH_PREFIX`: Installation prefix for this modernish installation (e.g.
  /usr/local).
* `$MSH_CONFIG`: Path to modernish user configuration directory.
* `$ME`: Path to the current program. Replacement for `$0`. This is
  necessary if the hashbang path `#!/usr/bin/env modernish` is used, or if
  the program is launched like `sh /path/to/bin/modernish
  /path/to/script.sh`, as these set `$0` to the path to bin/modernish and
  not your program's path.
* `$MSH_SHELL`: Path to the default shell for this modernish installation,
  chosen at install time (e.g. /bin/sh). This is a shell that is known to
  have passed all the modernish tests for fatal bugs. Cross-platform scripts
  should use it instead of hard-coding /bin/sh, because on some operating
  systems (NetBSD, OpenBSD, Solaris) /bin/sh is not POSIX compliant.
* `$SIGPIPESTATUS`: The exit status of a command killed by `SIGPIPE` (a
  broken pipe). For instance, if you use `grep something somefile.txt |
  more` and you quit `more` before `grep` is finished, `grep` is killed by
  SIGPIPE and exits with that particular status. Some modernish functions,
  such as `harden` and `traverse`, need to handle such a SIGPIPE exit
  specially to avoid unduly killing the program. The exact value of this
  exit status is shell-specific, so modernish runs a quick test to determine
  it at initialisation time.    
  If `SIGPIPE` was set to ignore by the process that invoked the current
  shell, `SIGPIPESTATUS` can't be detected and is set to the special value
  99999. See also the description of the
  [`WRN_NOSIGPIPE`](#user-content-warning-ids)
  ID for
  [`thisshellhas`](#user-content-feature-testing).
* `$DEFPATH`: The default system path guaranteed to find compliant POSIX
  utilities, as given by `getconf PATH`.

### Control character, whitespace and shell-safe character constants ###

POSIX does not provide for the quoted C-style escape codes commonly used in
bash, ksh and zsh (such as `$'\n'` to represent a newline character),
leaving the standard shell without a convenient way to refer to control
characters. Modernish provides control character constants (read-only
variables) with hexadecimal suffixes `$CC01` .. `$CC1F` and `$CC7F`, as well as `$CCe`,
`$CCa`, `$CCb`, `$CCf`, `$CCn`, `$CCr`, `$CCt`, `$CCv` (corresponding with
`printf` backslash escape codes). This makes it easy to insert control
characters in double-quoted strings.

More convenience constants, handy for use in bracket glob patterns for use
with `case` or modernish `match`:

* `$CONTROLCHARS`: All ASCII control characters.
* `$WHITESPACE`: All ASCII whitespace characters.
* `$ASCIIUPPER`: The ASCII uppercase letters A to Z.
* `$ASCIILOWER`: The ASCII lowercase letters a to z.
* `$ASCIIALNUM`: The ASCII alphanumeric characters 0-9, A-Z and a-z.
* `$SHELLSAFECHARS`: Safelist for shell-quoting.
* `$ASCIICHARS`: The complete set of ASCII characters (minus NUL).


## Legibility aliases ##

A few aliases that seem to make the shell language look slightly friendlier:

    alias not='! '              # more legible synonym for '!'
    alias so='[ "$?" -eq 0 ]'   # test preceding command's success with
                                # 'if so;' or 'if not so;'
    alias forever='while :;'    # indefinite loops: forever do <stuff>; done


## Enhanced exit ##

`exit`: extended usage: `exit` [ `-u` ] [ *status* [ *message* ] ]    
* As per standard, if *status* is not specified, it defaults to the exit
  status of the command executed immediately prior to `exit`.
* Any remaining arguments after *status* are combined, separated by spaces,
  and taken as a *message* to print on exit. The message shown is preceded by
  the name of the current program (`$ME` minus directories). Note that it is
  not possible to skip *status* while specifing a *message*.
* If the `-u` option is given, and the shell function `showusage` is defined,
  that function is run in a subshell before exiting. It is intended to print
  a message showing how the command should be invoked. The `-u` option has no
  effect if the script has not defined a `showusage` function.
* If *status* is non-zero, the *message* and the output of the `showusage`
  function are redirected to standard error.


## Reliable emergency halt ##

`die`: reliably halt program execution, even from within subshells, optionally
printing an error message. Note that `die` is meant for an emergency program
halt only, i.e. in situations were continuing would mean the program is in an
inconsistent or undefined state. Shell scripts running in an inconsistent or
undefined state may wreak all sorts of havoc. They are also notoriously
difficult to terminate correctly, especially if the fatal error occurs within
a subshell: `exit` won't work then. That's why `die` is optimised for
killing *all* the program's processes (including subshells and external
commands launched by it) as quickly as possible. It should never be used for
exiting the program normally.

On interactive shells, `die` behaves differently. It does not kill or exit your
shell; instead, it issues `SIGINT` to the shell to abort the execution of your
running command(s), which is equivalent to pressing Ctrl+C.

Usage: `die` [ *message* ]

A special `DIE` pseudosignal can be trapped (using plain old `trap` or
[`pushtrap`](#user-content-the-trap-stack))
to perform emergency cleanup commands upon invoking `die`.
On interactive shells, `DIE` is simply an alias for `SIGINT`.
On non-interactive shells, `DIE` traps are separate. In order to kill the
malfunctioning program as quickly as possible (hopefully before it has a chance
to delete all your data), `die` doesn't wait for those traps to complete before
killing the program. Instead, it executes each `DIE` trap simultaneously as a
background job, then gathers the process IDs of the main shell and all its
subprocesses, sending `SIGKILL` to all of them except any `DIE` trap processes.

(One case where `die` is limited is when the main shell program has exited,
but several runaway background processes that it forked are still going. If
`die` is called by one of those background processes, then it will kill that
background process and its subshells, but not the others. This is due to an
inherent limitation in the design of POSIX operating systems. When the main
shell exits, its surviving background processes are detached from the
process hierarchy and become independent from one another, with no way to
determine that they once belonged to the same program.)


## Low-level shell utilities ##

`insubshell`: easily check if you're currently running in a
[subshell environment](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_12)
(usually called simply *subshell*), that is, a copy of the parent shell that
starts out as an exact duplicate except for traps. This is not to be confused
with a newly initialised shell that is merely a child process of the current
shell, which is sometimes (erroneously) called a "subshell" as well.    
Usage: `insubshell` [ `-p` | `-u` ]    
This function returns success (0) if it was called from within a subshell
and non-success (1) if not. One of two options can be given:
* `-p`: Store the process ID (PID) of the current subshell or main shell
  in `REPLY`. (Note that on AT&T ksh93, which does not fork a new process
  for non-background subshells, that PID is same as the main shell's except
  for background jobs.)
* `-u`: Store an identifier in `REPLY` that is useful for determining if
  you've entered a subshell relative to a previously stored identifier. The
  content and format are unspecified and shell-dependent.

`setstatus`: manually set the exit status `$?` to the desired value. The
function exits with the status indicated. This is useful in conditional
constructs if you want to prepare a particular exit status for a subsequent
'exit' or 'return' command to inherit under certain circumstances.

`isvarname`: Check if argument is valid portable identifier in the shell,
that is, a portable variable name, shell function name or long-form shell
option name. (Modernish requires portable names everywhere; for example,
accented or non-Latin characters in variable names are not supported.)

`isset`: check if a variable, shell function or option is set. Usage:

* `isset` *varname*: Check if a variable is set.
* `isset -v` *varname*: Id.
* `isset -x` *varname*: Check if variable is exported.
* `isset -r` *varname*: Check if variable is read-only.
* `isset -f` *funcname*: Check if a shell function is set.
* `isset -`*optionletter* (e.g. `isset -C`): Check if shell option is set.
* `isset -o` *optionname*: Check if shell option is set by long name.

Exit status: 0 if the item is set; 1 if not; 2 if the argument is not
recognised as a syntactically valid identifier.

When checking a shell option, a nonexistent shell option is not an error,
but returns the same result as an unset shell option. (To check if a shell
option exists, use [`thisshellhas`](#user-content-feature-testing).

Note: just `isset -f` checks if shell option `-f` (a.k.a. `-o noglob`) is
set, but with an extra argument, it checks if a shell function is set.
Similarly, `isset -x` checks if shell option `-x` (a.k.a `-o xtrace`)
is set, but `isset -x` *varname* checks if a variable is exported. If you
use unquoted variable expansions here, make sure they're not empty, or
the shell's empty removal mechanism will cause the wrong thing to be checked
(even in `use safe` mode).

`unexport`: the opposite of `export`. Unexport a variable while preserving
its value, or (while working under `set -a`) don't export it at all.
Usage is like `export`, with the caveat that variable assignment arguments
containing non-shellsafe characters or expansions must be quoted as
appropriate, unlike in some specific shell implementations of `export`.
(To get rid of that headache, [`use safe`](#user-content-use-safe).)


## Quoting strings for subsequent parsing by the shell ##

`shellquote`: Quote the values of specified variables in such a way that the
values are suitable for parsing by the shell as string literals. This is
essential for the safe use of `eval` or any other context where the shell
must parse untrusted input. `shellquote` only uses quoting mechanisms
specified by POSIX, so the quoted values it produces are safe to parse
in any POSIX shell. It uses a highly optimised quoting algorithm that
combines quoting with backslashes, single quotes and double quotes to
minimise growth when quoting repeatedly.    
Usage: `shellquote` [ `-f`|`+f` ] *varname* [ [ `-f`|`+f` ] *varname* ... ]    
The values of the variables specified by name are shell-quoted and stored
back into those variables. By default, a value is only quoted if it contains
characters not present in `$SHELLSAFECHARS`. An `-f` argument forces
unconditional quoting for subsequent variables, disabling optimisations
that may leave shell-safe characters unquoted; an `+f` argument restores
default behaviour. `shellquote` returns success (0) if all variables were
processed successfully, and non-success (1) if any undefined (unset)
variables were encountered. In the latter case, any set variables still get
their values quoted.

`shellquoteparams`: shell-quote the current shell's positional parameters
in-place.

`storeparams`: store the positional parameters, or a sub-range of them,
in a variable, in a shellquoted form suitable for restoration using
`eval "set -- $varname"`. For instance: `storeparams -f2 -t6 VAR`
quotes and stores `$2` to `$6` in `VAR`.


## The stack ##

`push` & `pop`: every variable and shell option gets its own stack. For
variables, both the value and the set/unset state is (re)stored. Usage:

* `push` [ `--key=`*value* ] *item* [ *item* ... ]
* `pop` [ `--keepstatus` ] [ `--key=`*value* ] *item* [ *item* ... ]

where *item* is a valid portable variable name, a short-form shell option
(dash plus letter), or a long-form shell option (`-o` followed by an option
name, as two arguments). The precise shell options supported (other than the
ones guaranteed by POSIX) depend on the shell modernish is running on. For
cross-shell compatibility, nonexistent shell options are treated as unset.

Before pushing or popping anything, both functions check if all the given
arguments are valid and `pop` checks all items have a non-empty stack. This
allows pushing and popping groups of items with a check for the integrity of
the entire group. `pop` exits with status 0 if all items were popped
successfully, and with status 1 if one or more of the given items could not
be popped (and no action was taken at all).

The `--key=` option is an advanced feature that can help different modules
or funtions to use the same variable stack safely. If a key is given to
`push`, then for each *item*, the given key *value* is stored along with the
variable's value for that position in the stack. Subsequently, restoring
that value with `pop` will only succeed if the key option with the same key
value is given to the `pop` invocation. Similarly, popping a keyless value
only succeeds if no key is given to `pop`. If there is any key mismatch, no
changes are made and pop returns status 2. For instance, if a function
pushes all its values with something like `--key=myfunction`, it can do a
loop like `while pop --key=myfunction var; do ...` even if `var` already has
other items on its stack that shouldn't be tampered with. Note that this is
a robustness/convenience feature, not a security feature; the keys are not
hidden in any way. (The [var/setlocal](#user-content-use-varsetlocal)
module, which provides stack-based local variables, internally makes use of
this feature.)

If the `--keepstatus` option is given, `pop` will exit with the
exit status of the command executed immediately prior to calling `pop`. This
can avoid the need for awkward workarounds when restoring variables or shell
options at the end of a function. However, note that this makes failure to pop
(stack empty or key mismatch) a fatal error that kills the program, as `pop`
no longer has a way to communicate this through its exit status.

### The shell options stack ###

The shell options stack allows saving and restoring the state of any shell
option available to the `set` builtin using `push` and `pop` commands with
a syntax similar to that of `set`.

Long-form shell options are matched to their equivalent short-form shell
options, if they exist. For instance, on all POSIX shells, `-f` is
equivalent to `-o noglob`, and `push -o noglob` followed by `pop -f` works
correctly. (This works even for shell-specific short & long option
equivalents; modernish internally does a check to find any equivalent.)

On shells with a dynamic `no` option name prefix, that is on ksh, zsh and
yash (where, for example, `noglob` is the opposite of `glob`), the `no`
prefix is ignored, so something like `push -o glob` followed by `pop -o
noglob` does the right thing. But this depends on the shell and should never
be used in cross-shell scripts.

To facilitate cross-shell scripting, it is fine to push and pop shell
options that may not exist on the current shell; nonexistent options are
considered unset for stack purposes.

### The trap stack ###

`pushtrap` and `poptrap`: traps are now also stack-based, so that each
program component or library module can set its own trap commands
without interfering with others.

Note an important difference between the trap stack and stacks for variables
and shell options: pushing traps does not save them for restoring later, but
adds them alongside other traps on the same signal. All pushed traps are
active at the same time and are executed from last-pushed to first-pushed
when the respective signal is triggered. Traps cannot be pushed and popped
using `push` and `pop` but use dedicated commands as follows.

Usage:

* `pushtrap` [ `--key=`*value* ] [ `--nosubshell` ] [ `--` ] *command* *sigspec* [ *sigspec* ... ]
* `poptrap` [ `--key=`*value* ] [ `--` ] *sigspec* [ *sigspec* ... ]

`pushtrap` works like regular `trap`, with the following exceptions:

* Adds traps for a signal without overwriting previous ones.
  (However, any traps set prior to initialising modernish, or by bypassing
  the modernish 'trap' alias to access the system command directly, *will*
  be overwritten by a `pushtrap` for the same signal. To remedy this, you
  can issue a simple `trap` command; as modernish prints the traps, it will
  quietly detect ones it doesn't yet know about and make them work nicely
  with the trap stack.)
* Unlike regular traps, a stack-based trap does not cause a signal to be
  ignored. Setting one will cause it to be executed upon the shell receiving
  that signal, but after the stack traps complete execution, modernish re-sends
  the signal to the main shell, causing it to behave as if no trap were set
  (unless a regular POSIX trap is also active).
  Thus, `pushtrap` does not accept an empty *command* as it would be pointless.
* Each stack trap is executed in a new subshell to keep it from interfering
  with others. This means a stack trap cannot change variables except within
  its own environment, and 'exit' will only exit the trap and not the program.
  The `--nosubshell` option overrides this behaviour, causing that particular
  trap to be executed in the main shell environment instead. This is not
  recommended if not absolutely needed, as you have to be extra careful to
  avoid exiting the shell or otherwise interfere with other stack traps.
* Each stack trap is executed with `$?` initially set to the exit status
  that was active at the time the signal was triggered.
* Stack traps do not have access to the positional parameters.
* `pushtrap` stores current `$IFS` (field splitting) and `$-` (shell options)
  along with the pushed trap. Within the subshell executing each stack trap,
  modernish restores `IFS` and the shell options `f` (`noglob`), `u`
  (`nounset`) and `C` (`noclobber`) to the values in effect during the
  corresponding `pushtrap`. This is to avoid unexpected effects in case a trap
  is triggered while temporary settings are in effect.
  The `--nosubshell` option disables this functionality for the trap pushed.
* The `--key` option applies the keying functionality inherited from
  [plain `push`](#user-content-the-stack) to the trap stack.
  It works the same way, so the description is not repeated here.

`poptrap` takes just signal names or numbers as arguments. It takes the
last-pushed trap for each signal off the stack, storing the commands that
was set for those signals into the REPLY variable, in a format suitable for
re-entry into the shell. Again, the `--key` option works as in
[plain `pop`](#user-content-the-stack).

Stack-based traps, like native shell traps, are reset upon entering a
subshell (such as a command substitution or a series of commands enclosed in
parentheses). However, commands for printing traps will print the traps for
the parent shell, until another `trap`, `pushtrap` or `poptrap` command is
invoked, at which point all memory of the parent shell's traps is erased.

#### Trap stack compatibility considerations ####

Modernish tries hard to avoid incompatibilities with existing trap practice.
To that end, it intercepts the regular POSIX 'trap' command using an alias,
reimplementing and interfacing it with the shell's builtin trap facility
so that plain old regular traps play nicely with the trap stack. You should
not notice any changes in the POSIX 'trap' command's behaviour, except for
the following:

* The regular 'trap' command does not overwrite stack traps (but does
  overwrite previous regular traps).
* Unlike zsh's native trap command, signal names are case insensitive.
* Unlike dash's native trap command, signal names may have the `SIG` prefix;
  that prefix is quietly accepted and discarded.
* Setting an empty trap action to ignore a signal only works fully (passing
  the ignoring on to child processes) if there are no stack traps associated
  with the signal; otherwise, an empty trap action merely suppresses the
  signal's default action for the current process -- e.g., after executing
  the stack traps, it keeps the shell from exiting.
* The 'trap' command with no arguments, which prints the traps that are set
  in a format suitable for re-entry into the shell, now also prints the
  stack traps as 'pushtrap' commands. (`bash` users might notice the `SIG`
  prefix is not included in the signal names written.)
* The bash/yash-style '-p' option, including its yash-style `--print`
  equivalent, is now supported on all shells. If further arguments are
  given after that option, they are taken as signal specifications and
  only the commands to recreate the traps for those signals are printed.
* Saving the traps to a variable using command substitution (as in:
  `var=$(trap)`) now works on every shell supported by modernish, including
  (d)ash, mksh and zsh.
* To reset (unset) a trap, the modernish 'trap' command accepts both
  [valid POSIX syntax](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_28_03)
  and legacy bash/(d)ash/zsh syntax, like `trap INT` to unset a SIGINT
  trap (which only works if the 'trap' command is given exactly one
  argument). Note that this is for compatibility with existing scripts only.

POSIX traps for each signal are always executed after that signal's stack-based
traps; this means they should not rely on modernish modules that use the trap
stack to clean up after themselves on exit, as those cleanups would already
have been done.

Modernish introduces a new `DIE` pseudosignal whose traps are
executed upon invoking `die`.
See the [`die` description](#user-content-reliable-emergency-halt) for
more information.

On interactive shells, `INT` traps (both POSIX and stack) are cleared out
after executing them once. This is because [`die`](#user-content-reliable-emergency-halt)
uses SIGINT for cleanup and command interruption on interactive shells,
with the `DIE` signal name turned into an alias for `INT`.
As a side effect of this special handling, `INT` traps on interactive
shells do not have access to the positional parameters and cannot
return from shell functions.

### Positional parameters stack ###

`pushparams` and `popparams`: push and pop the complete set of positional
parameters. No arguments are supported.

### Stack query and maintenance functions ###

For the four functions below, *item* can be:
* a valid portable variable name
* a short-form shell option: dash plus letter
* a long-form shell option: `-o` followed by an option name (two arguments)
* `@` to refer to the [positional parameters stack](#user-content-positional-parameters-stack)
* `--trap=`*SIGNAME* to refer to the trap stack for the indicated signal

`stackempty` [ `--key=`*value* ] [ `--force` ] *item*: Tests if the stack
for an item is empty. Returns status 0 if it is, 1 if it is not. The key
feature works as in [`pop`](#user-content-the-stack): by default, a key
mismatch is considered equivalent to an empty stack. If `--force` is given,
this function ignores keys altogether.

`stacksize` [ `--silent` | `--quiet` ] *item*: Leaves the size of a stack in
the `REPLY` variable and, if option `--silent` or `--quiet` is not given,
writes it to standard output.
The size of the complete stack is returned, even if some values are keyed.

`printstack` [ `--quote` ] *item*: Outputs a stack's content.
Option `--quote` shell-quotes each stack value before printing it, allowing
for parsing multi-line or otherwise complicated values.
Column 1 to 7 of the output contain the number of the item (down to 0).
If the item is set, column 8 and 9 contain a colon and a space, and
if the value is non-empty or quoted, column 10 and up contain the value.
Sets of values that were pushed with a key are started with a special
line containing `--- key: `*value*. A subsequent set pushed with no key is
started with a line containing `--- (key off)`.
Returns status 0 on success, 1 if that stack is empty.

`clearstack` [ `--key=`*value* ] [ `--force` ] *item* [ *item* ... ]:
Clears one or more stacks, discarding all items on it.
If (part of) the stack is keyed or a `--key` is given, only clears until a
key mismatch is encountered. The `--force` option overrides this and always
clears the entire stack (be careful, e.g. don't use within
[`setlocal` ... `endlocal`](#user-content-use-varsetlocal)).
Returns status 0 on success, 1 if that stack was already empty, 2 if
there was nothing to clear due to a key mismatch.

## Hardening: emergency halt on error ##

`harden`: modernish's replacement for `set -e` a.k.a. `set -o errexit` (which is
[fundamentally](https://lists.gnu.org/archive/html/bug-bash/2012-12/msg00093.html)
[flawed](http://mywiki.wooledge.org/BashFAQ/105),
not supported and will break the library).

`harden` installs a shell function that hardens a particular command by
checking its exit status against values indicating error or system failure.
Exactly what exit statuses signify an error or failure depends on the
command in question; this should be looked up in the
[POSIX specification](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/contents.html)
(under "Utilities") or in the command's `man` page or other documentation.

If the command fails, the function installed by `harden` calls `die`, so it
will reliably halt program execution, even if the failure occurred within a
subshell (for instance, in a pipe construct or command substitution).

`harden` (along with `use safe`) is an essential feature for robust shell
programming that current shells lack. In shell programs without modernish,
proper error checking is too inconvenient and therefore rarely done. It's often
recommended to use `set -e` a.k.a `set -o errexit`, but that is broken in
various strange ways (see links above) and the idea is often abandoned. So,
all too often, shell programs simply continue in an inconsistent state after a
critical error occurs, occasionally wreaking serious havoc on the system.
Modernish `harden` was designed to help solve that problem properly.

Usage:

`harden` [ `-f` *funcname* ] [ `-[cSpXtPE]` ] [ `-e` *testexpr* ]
[ *var*`=`*value* ... ] [ `-u` *var* ... ] *command_name_or_path*
[ *command_argument* ... ]

The `-f` option hardens the command as the shell function *funcname* instead
of defaulting to *command_name_or_path* as the function name. (If the latter
is a path, that's always an invalid function name, so the use of `-f` is
mandatory.)

The `-c` option causes *command_name_or_path* to be hardened and run
immediately instead of setting a shell function for later use. This option
is meant for commands that run once; it is not efficient for repeated use.
It cannot be used together with the `-f` option.

The `-S` option allows specifying several possible names/paths for a
command. It causes the *command_name_or_path* to be split by comma and
interpreted as multiple names or paths to search. The first name or path
found is used. Requires `-f`.

The `-e` option, which defaults to `>0`, indicates the exit statuses
corresponding to a fatal error. It depends on the command what these are;
consult the POSIX spec and the manual pages.
The status test expression *testexpr*, argument
to the `-e` option, is like a shell arithmetic
expression, with the binary operators `==` `!=` `<=` `>=` `<` `>` turned
into unary operators referring to the exit status of the command in
question. Assignment operators are disallowed. Everything else is the same,
including `&&` (logical and) and `||` (logical or) and parentheses.
Note that the expression needs to be quoted as the characters used in it
clash with shell grammar tokens.

The `-X` option causes `harden` to always search for and harden an external
command, even if a built-in command by that name exists.

The `-E` option causes the hardening function to consider it a fatal error
if the hardened command writes anything to the standard error stream. This
option allows hardening commands (such as
[`bc`](pubs.opengroup.org/onlinepubs/9699919799/utilities/bc.html#tag_20_09_14))
where you can't rely on the exit status to detect an error. The text written
to standard error is passed on as part of the error message printed by
`die`. Note that:
* Intercepting standard error necessitates that the command be executed from a
  subshell. This means any builtins or shell functions hardened with `-E` cannot
  influence the calling shell (e.g. `harden -E cd` renders `cd` ineffective).
* `-E` does not disable exit status checks; by default, any exit status greater
  than zero is still considered a fatal error as well. If your command does not
  even reliably return a 0 status upon success, then you may want to add `-e
  '>125'`, limiting the exit status check to reserved values indicating errors
  launching the command and signals caught.

The `-p` option causes `harden` to search for commands using the
system default path (as obtained with `getconf PATH`) as opposed to the
current `$PATH`. This ensures that you're using a known-good external
command that came with your operating system. By default, the system-default
PATH search only applies to the command itself, and not to any commands that
the command may search for in turn. But if the `-p` option is specified at
least twice, or if the command is a shell function (hardened under another name
using `-f`), the command is run in a subshell with `PATH` exported as the
default path, which is equivalent to adding a `PATH=$DEFPATH` assignment
argument (see [below](#user-content-important-note-on-variable-assignments)).

Examples:

    harden make                           # simple check for status > 0
    harden -f tar '/usr/local/bin/gnutar' # id.; be sure to use this 'tar' version
    harden -e '> 1' grep                  # for grep, status > 1 means error
    harden -e '==1 || >2' gzip            # 1 and >2 are errors, but 2 isn't (see manual)

### Important note on variable assignments ###

As far as the shell is concerned, hardened commands are shell functions and
not external or builtin commands. This essentially changes one behaviour of
the shell: variable assignments preceding the command will not be local to
the command as usual, but *will persist* after the command completes.
(POSIX technically makes that behaviour
[optional](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_09_01)
but all current shells behave the same in POSIX mode.)

For example, this means that something like

    harden -e '>1' grep
    # [...]
    LC_ALL=C grep regex some_ascii_file.txt

should never be done, because the meant-to-be-temporary `LC_ALL` locale
assignment will persist and is likely to cause problems further on.

To solve this problem, `harden` supports adding these assignments as
part of the hardening command, so instead of the above you do:

    harden -e '>1' LC_ALL=C grep
    # [...]
    grep regex some_ascii_file.txt

With the `-u` option, `harden` also supports unsetting variables for the
duration of a command, e.g.:

    harden -e '>1' -u LC_ALL grep

Pitfall alert: if the `-u` option is used, this causes the hardened command to
run in a subshell with those variables unset, because using a subshell is the
only way to avoid altering those variables' state in the main shell. This is
usually fine, but note that a builtin command hardened with use of `-u` cannot
influence the calling shell. For instance, something like `harden -u LC_ALL cd`
renders `cd` ineffective: the working directory is only changed within the
subshell which is then immediately left.

The same happens if you harden a shell function under another name using
`-f` while adding environment variable assignments (or using the `-p`
option, which effectively adds `PATH=$DEFPATH`). The hardened function
will not be able to influence the main shell. Also note that the hardening
function will export the assigned environment variables for the duration of
that subshell, so those variables will be inherited by any external command
run from the hardened function. (While hardening shell functions using
`harden` is possible, it's not really recommended and it's better to call
`die` directly in your shell function upon detecting an error.)

### Hardening while allowing for broken pipes ###

If you're piping a command's output into another command that may close
the pipe before the first command is finished, you can use the `-P` option
to allow for this:

    harden -e '==1 || >2' -P gzip       # also tolerate gzip being killed by SIGPIPE
    gzip -dc file.txt.gz | head -n 10	# show first 10 lines of decompressed file

`head` will close the pipe of `gzip` input after ten lines; the operating
system kernel then kills `gzip` with the PIPE signal before it's finished,
causing a particular exit status that is greater than 128. This exit status
would normally make `harden` kill your entire program, which in the example
above is clearly not the desired behaviour. If the exit status caused by a
broken pipe were known, you could specifically allow for that exit status in
the status expression. The trouble is that this exit status varies depending
on the shell and the operating system. The `-p` option was made to solve
this problem: it automatically detects and whitelists the correct exit
status corresponding to SIGPIPE termination on the current system.

Tolerating SIGPIPE is an option and not the default, because in many
contexts it may be entirely unexpected and a symptom of a severe error if a
command is killed by a broken pipe. It is up to the programmer to decide
which commands should expect SIGPIPE and which shouldn't.

*Tip:* It could happen that the same command should expect SIGPIPE in one
context but not another. You can create two hardened versions of the same
command, one that tolerates SIGPIPE and one that doesn't. For example:

    harden -f hardGrep -e '>1' grep     # hardGrep does not tolerate being aborted
    harden -f pipeGrep -e '>1' -P grep  # pipeGrep for use in pipes that may break

*Note:* If `SIGPIPE` was set to ignore by the process invoking the current
shell, the `-p` option has no effect, because no process or subprocess of
the current shell can ever be killed by `SIGPIPE`. However, this may cause
various other problems and you may want to refuse to let your program run
under that condition.
[`thisshellhas WRN_NOSIGPIPE`](#user-content-warning-ids) can help
you easily detect that condition so your program can make a decision. See
the [WRN_NOSIGPIPE description](#user-content-warnig-ids) for more information.

### Tracing the execution of hardened commands ###

The `-t` option will trace command output. Each execution of a command
hardened with `-t` causes the full command line to be output to standard
error, in the following format:

    [functionname]> commandline

where `functionname` is the name of the shell function used to harden the
command and `commandline` is the complete and actual command executed. The
`commandline` is properly shell-quoted in a format suitable for re-entry
into the shell (which is an enhancement over the builtin tracing facility on
most shells). If standard error is on a terminal that supports ANSI colours,
the tracing output will be colourised.

The `-t` option was added to `harden` because the commands that you harden
are often the same ones you would be particularly interested in tracing. The
advantage of using `harden -t` over the shell's builtin tracing facility
(`set -x` or `set -o xtrace`) is that the output is a *lot* less noisy,
especially when using a shell library such as modernish.

*Note:* Internally, `-t` uses the shell file descriptor 9, redirecting it to
standard error (using `exec 9>&2`). This allows tracing to continue to work
normally even for commands that redirect standard error to a file (which is
another enhancement over `set -x` on most shells). However, this does mean
`harden -t` conflicts with any other use of the file descriptor 9 in your
shell program.

If file descriptor 9 is already open before `harden` is called, `harden`
does not attempt to override this. This means tracing may be redirected
elsewhere by doing something like `exec 9>trace.out` before calling
`harden`. (Note that redirecting FD 9 on the `harden` command itself will
*not* work as it won't survive the run of the command.)


## Simple tracing of commands ##

Sometimes you just want to trace the execution of some specific commands as
in `harden -t` (see above) without actually hardening them against command
errors; you might prefer to do your own error handling. `trace` makes this
easy. It is modernish's replacement or complement for `set -x` a.k.a. `set
-o xtrace`.

`trace` is actually a shortcut for
`harden -t -P -e '>125 && !=255'` *commandname*. The
result is that the indicated command is automatically traced upon execution.
Other options, including `-f`, `-c` and environment variable assignments, are
as in `harden`.

A bonus is that you still get minimal hardening against fatal system errors.
Errors in the traced command itself are ignored, but your program is
immediately halted with an informative error message if the traced command:

- cannot be found (exit status 127);
- was found but cannot be executed (exit status 126);
- was killed by a signal other than `SIGPIPE` (exit status > 128, except
  the shell-specific exit status for `SIGPIPE`, and except 255 which is
  used by some utilities, such as `ssh` and `rsync`, to return an error).

*Note:* The caveat for command-local variable assignments for `harden` also
applies to `trace`. See
[Important note on variable assignments](#user-content-important-note-on-variable-assignments)
above.


## External commands without full path ##

`extern` is like `command` but always runs an external command, without
having to know or determine its location. This provides an easy way to
bypass a builtin, alias or function. It does the same `$PATH` search
the shell normally does when running an external command. For instance, to
guarantee running external `printf` just do: `extern printf ...`

Usage: `extern` [ `-p` ] [ `-v` ] *command* [ *argument* ... ]

* `-p`: use the operating system's default `PATH` (as determined by `getconf
  PATH`) instead of your current `$PATH` for the command search. This guarantees
  a path that finds all the standard utilities defined by POSIX, akin to
  [`command -p`](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/command.html#tag_20_22_04)
  but still guaranteeing an external command.
  (Note that `extern -p` is more reliable than `command -p` because many
  shell binaries don't ask the OS for the default path and have a wrong
  default path hard-coded in.)
* `-v`: don't execute *command* but show the full path name of the command that
  would have been executed. Any extra *argument*s are taken as more command
  paths to show, one per line. `extern` exits with status 0 if all the commands
  were found, 1 otherwise. This option can be combined with `-p`.


## Outputting strings ##

`putln`: prints each argument on a separate line. There is no processing of
options or escape codes. (Modernish constants `$CCn`, etc. can be used to insert
control characters in double-quoted strings. To process escape codes, use
[`printf`](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/printf.html)
instead.)

`put`: prints each argument separated by a space, without a trailing separator
or newline. Again, there is no processing of options or escape codes.

`echo`: This command is notoriously unportable and kind of broken, so is
**deprecated** in favour of `put` and `putln`. Modernish does provide its own
version of `echo`, but it is *only* activated if modernish is in the hashbang
path or otherwise is itself used as the shell (the "most portable" way of
running programs
[explained above](#user-content-two-basic-forms-of-a-modernish-program)).
If your script runs on a specific shell and sources modernish as a dot script
(`. modernish`), or if you use modernish interactively in your shell profile,
the shell-specific version of `echo` is left intact. This is to make it
possible to add modernish to existing shell-specific scripts without breaking
anything, while still providing one consistent `echo` for cross-shell scripts.

The modernish version of `echo`, if active, does not interpret any escape codes
and supports only one option, `-n`, which, like BSD `echo`, suppresses the
final newline. However, unlike BSD `echo`, if `-n` is the only argument, it is
not interpreted as an option and the string `-n` is printed instead. This makes
it safe to output arbitrary data using this version of `echo` as long as it is
given as a single argument (using quoting if needed).


## Enhanced dot scripts ##

`source`: bash/zsh-style `source` command now available to all POSIX
shells, complete with optional positional parameters given as extra
arguments (which is not supported by POSIX `.`).


## Testing numbers, strings and files ##

Complete replacement for `test`/`[` in the form of speed-optimised shell
functions, so modernish scripts never need to use that `[` botch again.
Instead of inherently ambiguous `[` syntax (or the nearly-as-confusing
`[[` one), these familiar shell syntax to get more functionality, including:

### Integer number arithmetic tests and operations ###

`let`: implementation of `let` as in ksh, bash and zsh, now available to all
POSIX shells. This makes C-based signed integer arithmetic evaluation
available to every supported shell, with the exception of the unary "++" and
"--" operators (which have been given the capability designation ARITHPP).
This means `let` should be used for operations and tests, e.g. both
`let "x=5"` and `if let "x==5"; then`... are supported (note single = for
assignment, double == for comparison).
See POSIX
[2.6.4 Arithmetic Expansion](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_06_04)
for more information on the supported operators.

`isint`: test if a given argument is a decimal, octal or hexadecimal integer
number in valid POSIX shell syntax, ignoring leading (but not trailing) spaces
and tabs.

### String tests ###
    empty:        test if string is empty
    identic:      test if 2 strings are identical
    contains:     test if string 1 contains string 2
    startswith:   test if string 1 starts with string 2
    endswith:     test if string 1 ends with string 2
    match:        test if string matches a glob pattern
    ematch:       test if string matches an extended regex

### File type tests ###
These avoid the snags with symlinks you get with `[` and `[[`.
By default, symlinks are *not* followed. Add `-L` to operate on files
pointed to by symlinks instead of symlinks themselves (the `-L` makes
no difference if the operands are not symlinks).

    is present:    test if file exists (yields true even if invalid symlink)
    is -L present: test if file exists and is not an invalid symlink
    is sym:        test if file is symlink
    is -L sym:     test if file is a valid symlink
    is reg:        test if file is a regular file
    is -L reg:     test if file is regular or a symlink pointing to a regular
    is dir:        test if file is a directory
    is -L dir:     test if file is dir or symlink pointing to dir
    is fifo, is -L fifo, is socket, is -L socket, is blockspecial,
                   is -L blockspecial, is charspecial, is -L charspecial:
                   same pattern, you figure it out :)

### File comparison tests ###
By default, symlinks are *not* followed. Again, add `-L` to follow them.

    is newer:      test if file 1 is newer than file 2 (or if file 1 exists,
                   but file 2 doesn't)
    is older:      test if file 1 is older than file 2 (or if file 1 doesn't
                   exist, but file 2 does)
    is samefile:   test if file 1 and file 2 are the same file (hardlinks)
    is onsamefs:   test if file 1 and file 2 are on the same file system (for
                   non-regular, non-directory files, test the parent directory)
    is -L newer, is -L older, is -L samefile, is -L onsamefs:
                   same as above, but after resolving symlinks

### File status tests ###
Symlinks are followed.

    is nonempty:   test is file exists, is not an invalid symlink, and is
                   not empty (also works for dirs with read permission)
    is setuid:     test if file has user ID bit set
    is setgid:     test if file has group ID bit set

### I/O tests ###

    is onterminal: test if file descriptor is associated with a terminal

### File permission tests ###
These use a more straightforward logic than `[` and `[[`.
Any symlinks given are resolved, as these tests would be meaningless
for a symlink itself.

    can read:      test if we have read permission for a file
    can write:     test if we have write permission for a file or directory
                   (for directories, only true if traverse permission as well)
    can exec:      test if we have execute permission for a regular file
    can traverse:  test if we can enter (traverse through) a directory


## Basic string operations ##
The main modernish library contains functions for a few basic string
manipulation operations (because they are needed by other functions in the main
library). Currently these are:

### toupper/tolower ###
    toupper:       convert all letters to upper case
    tolower:       convert all letters to lower case

If no arguments are given, `toupper` and `tolower` copy standard input to
standard output, converting case.

If one or more arguments are given, they are taken as variable names (note:
they should be given without the `$`) and case is converted in the contents
of the specified variables, without reading input or writing output.

`toupper` and `tolower` try hard to use the fastest available method on the
particular shell your program is running on. They use built-in shell
functionality where available and working correctly, otherwise they fall back
on running an external utility.

Which external utility is chosen depends on whether the current locale uses
the Unicode UTF-8 character set or not. For non-UTF-8 locales, modernish
assumes the POSIX/C locale and `tr` is always used. For UTF-8 locales,
modernish tries hard to find a way to correctly convert case even for
non-Latin alphabets. A few shells have this functionality built in with
`typeset`. The rest need an external utility. Even in 2017, it is a real
challenge to find an external utility on an arbitrary POSIX-compliant system
that will correctly convert case for all applicable UTF-8 characters.
Modernish initialisation tries `tr`, `awk`, GNU `awk` and GNU `sed` before
giving up and issuing a
[warning ID](#user-content-warning-ids).
If `thisshellhas WRN_2UP2LOW`, it
means modernish is in a UTF-8 locale but has not found a way to convert
**C**ase for **NON ASCII** characters, so `toupper` and `tolower` will convert
only ASCII characters and leave any other characters in the string alone.

## Basic system utilities ##
Small utilities that should have been part of the standard shell, but
aren't. Since their implementation is inexpensive, they are part of the main
library instead of a module.

`mkcd`: make one or more directories, then, upon success, change into the
last-mentioned one. `mkcd` inherits `mkdir`'s usage, so options depend on
your system's `mkdir`; only the
[POSIX options](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/mkdir.html#tag_20_79_04)
are guaranteed.


## Modules ##

`use`: use a modernish module. It implements a simple Perl-like module
system with names such as 'safe', 'var/setlocal' and 'loop/select'.
These correspond to files 'safe.mm', 'var/setlocal.mm', etc. which are
dot scripts defining functionality. Any extra arguments to the `use`
command are passed on to the dot script unmodified, so modules can
implement option parsing to influence their initialisation.

### use safe ###
Does `IFS=''; set -f -u -C`, that is: field splitting and globbing are
disabled, variables must be defined before use, and output redirection using
`>` will not overwrite existing files (use `>|` to allow overwriting).

Essentially, this is a whole new way of shell programming,
eliminating most variable quoting headaches, protects against typos
in variable names wreaking havoc, and protects files from being
accidentally overwritten by output redirection.

Of course, you don't get field splitting and globbing. But modernish
provides various ways of enabling one or both only for the commands
that need them, `setlocal`...`endlocal` blocks chief among them
(see [`use var/setlocal`](#user-content-use-varsetlocal) below).

On interactive shells (or if `use safe -i` is given), also loads
convenience functions `fsplit` and `glob` to control and inspect the
state of field splitting and globbing in a more user friendly way.

*It is highly recommended that new modernish scripts start out with `use safe`.*
But this mode is not enabled by default because it will totally break
compatibility with shell code written for default shell settings.

### use var/arith ###
These shortcut functions are alternatives for using 'let'.

#### Arithmetic operator shortcuts ####
`inc`, `dec`, `mult`, `div`, `mod`: simple integer arithmetic shortcuts. The first
argument is a variable name. The optional second argument is an
arithmetic expression, but a sane default value is assumed (1 for inc
and dec, 2 for mult and div, 256 for mod). For instance, `inc X` is
equivalent to `X=$((X+1))` and `mult X Y-2` is equivalent to `X=$((X*(Y-2)))`.

`ndiv` is like `div` but with correct rounding down for negative numbers.
Standard shell integer division simply chops off any digits after the
decimal point, which has the effect of rounding down for positive numbers
and rounding up for negative numbers. `ndiv` consistently rounds down.

#### Arithmetic comparison shortcuts ####
These have the same name as their `test`/`[` option equivalents. Unlike
with `test`, the arguments are shell integer arith expressions, which can be
anything from simple numbers to complex expressions. As with `$(( ))`,
variable names are expanded to their values even without the `$`.

    Function:         Returns successfully if:
    eq <expr> <expr>  the two expressions evaluate to the same number
    ne <expr> <expr>  the two expressions evaluate to different numbers
    lt <expr> <expr>  the 1st expr evaluates to a smaller number than the 2nd
    le <expr> <expr>  the 1st expr eval's to smaller than or equal to the 2nd
    gt <expr> <expr>  the 1st expr evaluates to a greater number than the 2nd
    ge <expr> <expr>  the 1st expr eval's to greater than or equal to the 2nd

### use var/mapr ###
`mapr` (map records): Read delimited records from the standard input, invoking
a *callback* command with each input record as an argument and with up to
*quantum* arguments at a time. By default, an input record is one line of text.

Usage: `mapr` [ `-d` *delimiter* | `-D` ] [ `-n` *count* ] [ -s *count* ]
[ -c *quantum* ] *callback* [ *argument* ... ]

Options:

* `-d` *delimiter*: Use the single character *delimiter* to delimit input records,
  instead of the newline character. A `NUL` (0) character and multibyte
  characters are not supported.
* `-P`: Paragraph mode. Input records are delimited by sequences consisting of
  a newline plus one or more blank lines, and leading or trailing blank lines
  will not result in empty records at the beginning or end of the input. Cannot
  be used together with -d.
* `-s` *number*: Skip and discard the first *count* records read.
* `-n` *number*: Stop processing after passing a total of *number* records to
  invocation(s) of *callback*. If `-n` is not supplied or *number* is 0, all
  records are passed, except those skipped using `-s`.
* `-m` *length*: Pass at most *length* bytes of arguments to each call to
  *callback*. The default value depends on constraints set by the operating
  system. The length of each argument is rounded up to a multiple of 8 bytes.
  If *length* is 0, this limit is disabled.
* `-c` *quantum*: Pass at most *quantum* arguments at a time to each call to
  *callback*. If `-c` is not supplied or if *quantum* is 0, the number of
  arguments per invocation is not limited except by `-m`; whichever limit is
  reached first applies.

Arguments:

* *callback*: Call the *callback* command with the collected arguments each
  time *quantum* lines are read. The callback command may be a shell function or
  any other kind of command, and is executed from the same shell environment
  that invoked `mapr`. If the callback command exits with status 255, `mapr`
  aborts processing and exits with status 1. If the callback command is
  interrupted by the SIGPIPE signal, `mapr` aborts processing and exits with
  status `$SIGPIPESTATUS`. Other than that, it is a
  [fatal error](#user-content-reliable-emergency-halt)
  for the callback command to exit with a status \> 0.
* *argument*:  If there are extra arguments supplied on the mapr command line,
  they will be added before the collected arguments on each invocation on the
  callback command.

#### Differences from `mapfile` ####
`mapr` was inspired by the bash 4.x builtin command `mapfile` a.k.a.
`readarray`, and uses similar options, but there are important differences.

* `mapr` passes all the records as arguments to the callback command.
* `mapr` does not support assigning records directly to an array. Instead,
  all handling is done through the callback command (which could be a shell
  function that assigns its arguments to an array.)
* The callback command is specified directly instead of with a `-C` option,
  and it may consist of several arguments (as with `xargs`).
* The record separator itself is never included in the arguments passed
  to the callback command (so there is no `-t` option to remove it).
* `mapr` supports paragraph mode.
* If the callback command exits unsuccessfully, this is treated as a fatal
  error, except that status 255 merely aborts processing.

#### Differences from `xargs` ####
`mapr` shares important characteristics with
[`xargs`](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/xargs.html)
while avoiding its myriad pitfalls.

* Instead of being an external utility, `mapr` is fully integrated into the
  shell. The callback command can be a shell function or builtin, which can
  directly modify the shell environment.
* `mapr` is line-oriented by default, so it is safe to use for input
  arguments that contain spaces or tabs.
* `mapr` does not parse or modify the input arguments in any way, e.g. it
  does not process and remove quotes from them like `xargs` does.
* `mapr` supports paragraph mode.
* If the callback command exits unsuccessfully, this is treated as a fatal
  error, except that (like with `xargs`) status 255 merely aborts processing.

### use var/readf ###
`readf` reads arbitrary data from standard input into a variable until end
of file, converting it into a format suitable for passing to the
[`printf`](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/printf.html)
utility. For example, `readf var <foo; printf "$var" >bar` will copy foo to
bar. Thus, `readf` allows storing both text and binary files into shell
variables in a textual format suitable for manipulation with standard shell
facilities.

All non-printable, non-ASCII characters are converted to `printf` octal or
one-letter escape codes, except newlines. Not encoding newline characters
allows for better processing by line-based utilities such as `grep`, `sed`,
`awk`, etc. However, if the file ends in a newline, that final newline is
encoded to `\\n` to protect it from being stripped by command substitutions.

Usage: `readf` *varname*

Caveats:
* Best for small-ish files. The encoded file is stored in memory (a shell
  variable). For a binary file, encoding in `printf` format typically
  about doubles the size, though it could be up to four times as large.
* If the shell executing your program does not have `printf` as a builtin
  command, the external `printf` command will fail if the encoded file
  size exceeds the maximum length of arguments to external commands
  (`getconf ARG_MAX` will obtain this limit for your system). Shell builtin
  commands do not have this limit. Check for a `printf` builtin using
  [`thisshellhas`](#user-content-feature-testing) if you need to be sure,
  and always [`harden`](#user-content-hardening-emergency-halt-on-error)
  `printf`!

### use var/setlocal ###
Defines a new `setlocal`...`endlocal` shell code block construct with
arbitrary local variables and arbitrary local shell options, as well as
safe field splitting and pathname expansion operators.

Usage: `setlocal` [ *localitem* ... ]
[ [ `--split` | `--split=`*characters* ] [ `--glob` | `--nglob` ] `--` [ *word* ... ] ]
`;` `do` *commands* `;` `endlocal`

The *commands* are executed with the specified settings applied locally to
the `setlocal`...`endlocal` block.

Each *localitem* can be:

* A variable name with or without a `=` immediately followed by a value.
  This renders that variable local to the block, initially either unsetting
  it or assigning the value, which may be empty.
* A shell option letter immediately preceded by a `-` or `+` sign. This
  locally turns that shell option on or off, respectively. This follows the
  counterintuitive syntax of `set`. Long-form shell options like `-o`
  *optionname* and `+o` *optionname* are also supported. It depends on the
  shell what options are supported. Specifying a nonexistent option is a
  fatal error. Use [`thisshellhas`](#user-content-feature-testing) to check
  for a non-POSIX option's existence on the current shell before using it.

The `return` command exits the block, causing the global variables and
settings to be restored and resuming execution at the point immmediately
following `endlocal`. This is like a shell function. In fact, internally,
`setlocal` blocks **are** one-time shell functions that use
[the stack](#user-content-the-stack)
to save and restore variables and settings. Like any shell
function, a `setlocal` block exits with the exit status of the last command
executed within it or, with the status passed on by or given as an argument to
`return`.

The `break` and `continue` commands, when not used within a loop within the
block, also exit the block, but always with exit status 0. It's preferred to
use `return` instead. Note that `setlocal` creates a new loop context and
you cannot use `break` or `continue` to resume or break from enclosing loops
outside the `setlocal` block. (Shells with
[QRK_BCDANGER](#user-content-quirks) do in fact allow this, preventing
`endlocal` from restoring the global settings! Shells without this quirk
automatically protect against this.)

Within the block, the positional parameters (`$@`, `$1`, etc.) are always
local. By default, a copy is inherited from outside the block. Any changes to
the positional parameters made within the block will be discarded upon
exiting it.

However, if a `--` is present, the set of *word*s after `--` becomes the
positional parameters instead, after being modified by the `--split` or
`--glob`/`--nglob` operators if present, as follows:

* A simple `--split` subjects the *word*s to default field splitting.
* `--split=`*string* subjects the *word*s to field splitting based on the
  characters given in *string*.
* `--glob` causes each *word* (after split, if specified) to be treated
  as shell glob patterns and subjects each pattern to pathname expansion.
  Unmatched patterns are left untouched (i.e. resolve to themselves).
* The `--nglob` operator does the same as `--glob`, then also removes each
  unmatched pattern. Note that this includes patterns that do not contain
  any wildcard characters.

**Note:** These `--split` and `--glob`/`--nglob` operators do **not**
enable field splitting or pathname expansion within the block itself, but
only subject the *word*s after the `--` to them. If field splitting and
globbing are [disabled globally](#user-content-use-safe), this provides a
safe way to perform field splitting or globbing without actually enabling
them for any code. To illustrate this advantage, note the difference:

    # Field splitting is enabled for all unquoted expansions within the
    # setlocal block, which may be unsafe, so must quote "$foo" and "$bar".
    setlocal dir IFS=':'; do
        for dir in $PATH; do
	    somestuff "$foo" "$bar"
	done
    endlocal

    # The value of PATH is split at ':' and assigned to the positional
    # parameters, without enabling field splitting within the setlocal block.
    setlocal dir --split=':' -- $PATH; do
        for dir do
            somestuff $foo $bar
        done
    endlocal

**Important:**
The `--split` and `--glob`/`--nglob` operators are designed to be
used along with [safe mode](#user-content-use-safe). If they are used in
traditional mode, i.e. with field splitting and/or pathname expansion
globally active, you *must* make sure the *word*s after the `--` are
properly quoted as with any other command, otherwise you will have
unexpected duplicate splitting or pathname expansion.

**Other usage notes:**

* Although the `setlocal` declaration ends with `; do` as in a `while` or
  `until` loop, the code block is terminated with `endlocal` and not with
  `done`. Terminating it with `done` results in a misleading shell syntax
  error (end of file, or missing `}`), a side effect of how `setlocal` is
  implemented.
* `setlocal` blocks do **not** mix well with
  [`LOCAL`](#user-content-user-content-capabilities)
  (shell-native functionality for local variables), especially not on shells
  with `QRK_LOCALUNS` or `QRK_LOCALUNS2`. Use one or the other, but not
  both.
* A note of caution concerning loop constructs: Care should be taken not to
  use `break` and `continue` in ways that would cause execution to continue
  outside the `setlocal` block. Some shells do not allow `break` and `continue`
  to break out of a shell function (including the internal one-time shell
  function employed by setlocal), so thankfully this fails on those shells.
  But on others this succeeds, so global settings are not restored, wreaking
  havoc on the rest of your program. One way to avoid the problem is to
  envelop the entire loop in a `setlocal` block. Another is to exit the
  internal shell function using `return 1` and then add `|| break` or
  `|| continue` immediately after `endlocal`.
* zsh programmers may recognise `setlocal` as pretty much the equivalent of
  zsh's anonymous functions -- functionality that is hereby brought to all
  POSIX shells, albeit with a rather different syntax.

### use var/string ###
String comparison and manipulation functions.

`sortsbefore` and `sortsafter`: test if string 1 sorts before or after
string 2. The POSIX shell provides no standard built-in way of doing this.
These functions use built-in ways where available, or fall back on the
[expr](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/expr.html)
utility.    
Usage: `sortsbefore`|`sortsafter` *string1* *string2*

`trim`: strip whitespace from the beginning and end of a variable's value.
Whitespace is defined by the `[:space:]` character class. In the POSIX
locale, this is tab, newline, vertical tab, form feed, carriage return, and
space, but in other locales it may be different.
(On shells with [`BUG_NOCHCLASS`](#user-content-bugs),
[`$WHITESPACE`](#user-content-control-character-whitespace-and-shell-safe-character-constants)
is used to define whitesapce instead.) Optionally, a string of literal
characters can be provided in the second argument. Any characters appearing
in that string will then be trimmed instead of whitespace.
Usage: `trim` *varname* [ *characters* ]

`replacein`: Replace leading, `-t`railing or `-a`ll occurrences of a string by
another string in a variable.    
Usage: `replacein` [ `-t` | `-a` ] *varname* *oldstring* *newstring*

`append` and `prepend`: Append or prepend zero or more strings to a
variable, separated by a string of zero or more characters, avoiding the
hairy problem of dangling separators.
Usage: `append`|`prepend` [ `--sep=`*separator* ] [ `-Q` ] *varname* [ *string* ... ]    
If the separator is not specified, it defaults to a space character.
If the `-Q` option is given, each *string* is
[shell-quoted](#user-content-quoting-strings-for-subsequent-parsing-by-the-shell)
before appending or prepending.

### use sys/base ###
Some very common external commands ought to be standardised, but aren't. For
instance, the `which` and `readlink` commands have incompatible options on
various GNU and BSD variants and may be absent on other Unix-like systems.
This module provides a complete re-implementation of such basic utilities
written as modernish shell functions. Scripts that use the modernish version
of these utilities can expect to be fully cross-platform. They also have
various enhancements over the GNU and BSD originals.

#### use sys/base/readlink ####
`readlink`: Read the target of a symbolic link. Robustly handles weird
filenames such as those containing newline characters. Stores result in the
$REPLY variable and optionally writes it on standard output. Optionally
canonicalises each path, following all symlinks encountered (for this mode,
all but the last component must exist). Optionally shell-quote each item of
output for later parsing by the shell, separating multiple items with spaces
instead of newlines.

#### use sys/base/which ####
`which`: Outputs, and/or stores in the `REPLY` variable, either the first
available directory path to each given command, or all available paths,
according to the current `$PATH` or the system default path. Exits
successfully if at least one path was found for each command, or
unsuccessfully if none were found for any given command.

Usage: `which` [ `-[apqsnQ1]` ] [ `-P` *number* ] *program* [ *program* ... ]

* `-a`: List *a*ll executables found, not just the first one for each argument.
* `-p`: Search the system default *p*ath, not the current `$PATH`. This is the
  minimal path, specified by POSIX, that is guaranteed to find all the standard
  utilities.
* `-q`: Be *q*uiet: suppress all warnings.
* `-s`: *S*ilent operation: don't write output, only store it in the `REPLY`
  variable. Suppress warnings except, if you run `which -s` in a subshell,
  the warning that the `REPLY` variable will not survive the subshell.
* `-n`: When writing to standard output, do *n*ot write a final *n*ewline.
* `-Q`: Shell-*q*uote each unit of output. Separate by spaces instead
  of newlines. This generates a list of arguments in shell syntax,
  guaranteed to be suitable for safe parsing by the shell, even if the
  resulting pathnames should contain strange characters such as spaces or
  newlines and other control characters.
* `-1` (one): Output the results for at most *one* of the arguments in
  descending order of preference: once a search succeeds, ignore
  the rest. Suppress warnings except a subshell warning for `-s`.
  This is useful for finding a command that can exist under
  several names, for example:
  `which -f -1 gnutar gtar tar`    
  This option modifies which's exit status behaviour: `which -1`
  returns successfully if any match was found.
* `-f`: Consider it a [*f*atal error](#user-content-reliable-emergency-halt)
  if at least one of the given *program*s is not found. But if option `-1`
  is also given, only throw a fatal error if none are found.
* `-P`: Strip the indicated number of *p*athname elements from the output,
  starting from the right.
  `-P1`: strip `/program`;
  `-P2`: strip `/*/program`,
  etc. This is useful for determining the installation root directory for
  an installed package.

#### use sys/base/mktemp ####
A cross-platform shell implementation of 'mktemp' that aims to be just as
safe as native `mktemp`(1) implementations, while avoiding the problem of
having various mutually incompatible versions and adding several unique
features of its own.

Creates one or more unique temporary files, directories or named pipes,
atomically (i.e. avoiding race conditions) and with safe permissions.
The path name(s) are stored in $REPLY and optionally written to stdout.

Usage: `mktemp` [ `-dFsQCt` ] [ *template* ... ]

* `-d`: Create a directory instead of a regular file.
* `-F`: Create a FIFO (named pipe) instead of a regular file.
* `-s`: Silent. Store output in `$REPLY`, don't write any output or message.
* `-Q`: Shell-quote each unit of output. Separate by spaces, not newlines.
* `-C`: Automated cleanup.
        [Pushes a trap](#user-content-the-trap-stack)
        to remove the files
        on exit. On an interactive shell, that's all this option does. On a
        non-interactive shell, the following applies: Clean up on receiving
        SIGPIPE and SIGTERM as well. On receiving SIGINT, clean up if the
        option was given at least twice, otherwise notify the user of files
        left. On the invocation of
        [`die`](#user-content-reliable-emergency-halt),
        clean up if the option was given at least three times, otherwise notify
        the user of files left.
* `-t`: Prefix one temporary files directory to all the *template*s:
        `$TMPDIR/` if `TMPDIR` is set, `/tmp/` otherwise. The *template*s
        may not contain any slashes. If the template has neither any trailing
        `X`es nor a trailing dot, a dot is added before the random suffix.

The template defaults to `/tmp/temp.`. An suffix of random shell-safe ASCII
characters is added to the template to create the file. For compatibility with
other `mktemp` implementations, any optional trailing `X` characters in the
template are removed. The length of the suffix will be equal to the amount of
`X`es removed, or 10, whichever is more. The longer the random suffix, the
higher the security of using `mktemp` in a shared directory such as `tmp`.

Since `/tmp` is a world-writable directory shared by other users, for best
security it is recommended to create a private subdirectory using `mktemp -d`
and work within that.

Option `-C` cannot be used while invoking `mktemp` in a subshell, such as
in a command substitution. Modernish will detect this and treat it as a
fatal error. The reason is that a typical command substitution like
`tmpfile=$(mktemp -C)`
is incompatible with auto-cleanup, as the cleanup EXIT trap would be
triggered not upon exiting the program but upon exiting the command
substitution subshell that just ran `mktemp`, thereby immediately undoing
the creation of the file. Instead, do something like:
`mktemp -sC; tmpfile=$REPLY`

#### use sys/base/seq ####
A cross-platform implementation of `seq` that is more powerful and versatile
than native GNU and BSD `seq`(1) implementations. The core is written in
`bc`, the POSIX arbitrary-presision calculator language. That means this
`seq` inherits the capacity to handle numbers with a precision and size only
limited by computer memory, as well as the ability to handle input numbers
in any base from 1 to 16 and produce output in any base 1 and up.

Usage: `seq` [ `-w` ] [ `-f` *format* ] [ `-s` *string* ] [ `-S` *scale* ]
[ `-B` *base* ] [ `-b` *base* ] [ *first* [ *incr* ] ] *last*

`seq` prints a sequence of arbitrary-precision floating point numbers, one
per line, from *first* (default 1), to as near *last* as possible, in increments of
*incr* (default 1). If *first* is larger than *last*, the default *incr* is -1.

* `-w`: Equalise width by padding with leading zeros. The longest of the
	*first*, *incr* or *last* arguments is taken as the length that each
	output number should be padded to.
* `-f`: `printf`-style floating-point format. The format string is passed on
        (with an added `\n`) to `awk`'s builtin `printf` function. Because
        of that, the `-f` option can only be used if the output base is 10.
        Note that `awk`'s floating point precision is limited, so very
        large or long numbers will be rounded.
* `-s`: Use *string* to separate numbers. Default: newline. The terminator
        character remains a newline in any case (which is like GNU `seq`
        and differs from BSD `seq`).
* `-S`: Explicitly set the scale (number of digits after decimal point).
	Defaults to the largest number of digits after the decimal point
	among the *first*, *incr* or *last* arguments.
* `-B`: Set input and output base from 1 to 16. Defaults to 10.
* `-b`: Set arbitrary output base from 1. Defaults to input base.
        See the `bc`(1) manual for more infromation on the output format
        for bases greater than 16.

The `-S`, `-B` and `-b` options take shell integer numbers as operands. This
means a leading `0X` or `0x` denotes a hexadecimal number and (except on
shells with BUG_NOOCTAL) a leading `0` denotes an octal numnber.

For portability reasons, modernish `seq` always uses a dot (.) for the
floating point, never a comma, regardless of the system locale. This applies
both to command arguments and to output.

The `-w`, `-f` and `-s` options are inspired by GNU and BSD `seq`, mostly
emulating GNU where they differ. The `-S`, `-B` and `-b` options are
modernish enhancements based on `bc`(1) functionality.

#### use sys/base/rev ####
`rev` copies the specified files to the standard output, reversing the order
of characters in every line. If no files are specified, the standard input
is read.

Usage: like `rev` on Linux and BSD, which is like `cat` except that `-` is
a filename and does not denote standard input. No options are supported.

### use sys/dir ###
Functions for working with directories. So far I have:

#### use sys/dir/traverse ####
`traverse` is a fully cross-platform, robust replacement for `find` without
the snags of the latter. It is not line oriented but handles all data
internally in the shell. Any weird characters in file names (including
whitespace and even newlines) "just work", provided either
[`use safe`](#user-content-use-safe) is active or shell expansions are
properly quoted. This avoids many hairy
[common pitfalls with `find`](https://www.dwheeler.com/essays/filenames-in-shell.html)
while remaining compatible with all POSIX systems.

`traverse` recursively walks through a directory, executing a command for
each file and subdirectory found. That command is usually a handler shell
function in your program.

Unlike `find`, which is so smart its command line options are practically
their own programming language, `traverse` is dumb: it has minimal
functionality of its own. However, with a shell function as the command,
any functionality of 'find' and anything else can be programmed in the
shell language. Flexibility is unlimited. The `install.sh` script that comes
with modernish provides a good example of its practical use. See also the
[traverse-test](https://github.com/modernish/modernish/blob/master/share/doc/modernish/examples/traverse-test)
example program.

Usage: `traverse` [ `-d` ] [ `-F`] [ `-X` ] *directory* *command*

`traverse` calls *command*, once for each file found within the *directory*,
with one parameter containing the full pathname relative to the *directory*.
Any directories found within are automatically entered and traversed
recursively unless the *command* exits with status 1. Symlinks to
directories are not followed.

`find`'s `-prune` functionality is implemented by testing the command's exit
status. If the command indicated exits with status 1 for a directory, this
means: do not traverse the directory in question. For other types of files,
exit status 1 is the same as 0 (success). Exit status 2 means: stop the
execution of `traverse` and resume program execution. An exit status greater
than 2 indicates system failure and causes the program to abort.

`find`'s `-depth` functionality is implemented using the `-d` option. By
default, `traverse` handles directories first, before their contents. The
`-d` option causes depth-first traversal, so all entries in a directory will
be acted on before the directory itself. This applies recursively to
subdirectories. That means depth-first traversal is incompatible with
pruning, so returning status 1 for directories will have no effect.

find's `-xdev` functionality is implemented using the `-F` option. If this
is given, `traverse` will not descend into directories that are on another
file system than that of the directory given in the argument.

`xargs`-like functionality is implemented using the `-X` option. As many
items as possible are saved up before being passed to the command all at
once. This is also incompatible with pruning. Unlike `xargs`, the command is
only executed if at least one item was found for it to handle.

#### use sys/dir/countfiles ####
`countfiles`: Count the files in a directory using nothing but shell
functionality, so without external commands. (It's amazing how many pitfalls
this has, so a library function is needed to do it robustly.)

Usage: `countfiles` [ `-s` ] *directory* [ *globpattern* ... ]

Count the number of files in a directory, storing the number in `REPLY`
and (unless `-s` is given) printing it to standard output.
If any *globpattern*s are given, only count the files matching them.

### use sys/term ###
Utilities for working with the terminal.

#### use sys/term/readkey ####
`readkey`: read a single character from the keyboard without echoing back to
the terminal. Buffering is done so that multiple waiting characters are read
one at a time.

Usage: `readkey` [ `-E` *ERE* ] [ `-t` *timeout* ] [ `-r` ] [ *varname* ]

`-E`: Only accept characters that match the extended regular expression
*ERE* (the type of RE used by `grep -E`/`egrep`). `readkey` will silently
ignore input not matching the ERE and wait for input matching it.

`-t`: Specify a *timeout* in seconds (one significant digit after the
decimal point). After the timeout expires, no character is read and
`readkey` returns status 1.

`-r`: Raw mode. Disables INTR (Ctrl+C), QUIT, and SUSP (Ctrl+Z) processing
as well as translation of carriage return (13) to linefeed (10).

The character read is stored into the variable referenced by *varname*,
which defaults to `REPLY` if not specified.

### use opts/parsergen ###
Parsing of command line options for shell functions is a hairy problem.
Using `getopts` in shell functions is problematic at best, and manually
written parsers are very hard to do right. That's why this module provides
`generateoptionparser`, a command to generate an option parser: it takes
options specifying what variable names to use and what your function should
support, and outputs code to parse options for your shell function. Options
can be specified to require or not take arguments. Combining/stacking
options and arguments in the traditional UNIX manner is supported.

Only short (one-character) options are supported. Each option gets a
corresponding variable with a name with a specified prefix, ending in the
option character (hence, only option characters that are valid in variables
are supported, namely, the ASCII characters A-Z, a-z, 0-9 and the
underscore). If the option was not specified on the command line, the
variable is set, otherwise it is set to the empty value, or, if the option
requires an argument, the variable will contain that argument.

### use loop/cfor ###
A C-style for loop akin to `for (( ))` in bash/ksh/zsh, but unfortunately
not with the same syntax. For example, to count from 1 to 10:

    cfor 'i=1' 'i<=10' 'i+=1'; do
        echo "$i"
    done

(Note that `++i` and `i++` can only be used on shells with ARITHPP,
but `i+=1` or `i=i+1` can be used on all POSIX-compliant shells.)

### use loop/sfor ###
A C-style for loop with arbitrary shell commands instead of arithmetic
expressions. For example, to count from 1 to 10 with traditional shell
commands:

    sfor 'i=1' '[ "$i" -le 10 ]' 'i=$((i+1))'; do
        print "$i"
    done

or, with modernish commands:

    sfor 'i=1' 'le i 10' 'inc i'; do
        print "$i"
    done

### use loop/with ###

The shell lacks a very simple and basic loop construct, so this module
provides for an old-fashioned MS BASIC-style `for` loop, renamed a `with`
loop because we can't overload the reserved shell keyword `for`. Integer
arithmetic only. Usage:

    with <varname>=<value> to <limit> [ step <increment> ]; do
       # some commands
    done

To count from 1 to 10:

    with i=1 to 10; do
        print "$i"
    done

The value for `step` defaults to 1 if *limit* is equal to or greater
than *value*, and to -1 if *limit* is less than *value*. The latter is
a slight enhancement over the original BASIC `for` construct. So
counting backwards is as simple as `with i=10 to 1; do` (etc).        

### use loop/select ###
A complete and nearly accurate reimplementation of the `select` loop from
ksh, zsh and bash for POSIX shells lacking it. Modernish scripts running
on any POSIX shell can now easily use interactive menus.

(All the new loop constructs have one bug in common: as they start with
an alias that expands to two commands, you can't pipe a command's output
directly into such a loop. You have to enclose it in `{`...`}` as a
workaround. I have not found a way around this limitation that doesn't
involve giving up the familiar `do`...`done` syntax.)

---

## Appendix A ##

This is a list of shell capabilities and bugs that modernish tests for, so
that both modernish itself and scripts can easily query the results of these
tests. The all-caps IDs below are all usable with the
[`thisshellhas`](#user-content-feature-testing)
function. This makes it easy for a cross-platform modernish script to write
optimisations taking advantage of certain non-standard shell features,
falling back to a standard method on shells without these features. On the
other hand, if universal compatibility is not a concern for your script, it
is just as easy to require certain features and exit with an error message
if they are not present, or to refuse shells with certain known bugs.

Most feature/quirk/bug tests have their own little test script in the
`libexec/modernish/cap` directory. These tests are executed on demand, the
first time the capability or bug in question is queried using
`thisshellhas`. See `README.md` in that directory for further information.
The test scripts also document themselves in the comments.

Tests that are essential to the functioning of modernish are incorporated
into the main `bin/modernish` script; these are considered built-in tests,
and are immediately run and cached at initialisation time.
In the lists below, an ID in *`ITALICS`* denotes such a built-in test.

### Capabilities ###

Non-standard shell capabilities currently tested for are:

* `LEPIPEMAIN`: execute last element of a pipe in the main shell, so that
  things like *somecommand* `| read` *somevariable* work. (zsh, AT&T ksh,
  bash 4.2+)
* *`RANDOM`*: the `$RANDOM` pseudorandom generator.
  Modernish seeds it if detected. The variable is then set it to read-only
  whether the generator is detected or not, in order to block it from losing
  its special properties by being unset or overwritten, and to stop it being
  used if there is no generator. This is because some of modernish depends
  on `RANDOM` either working properly or being unset.    
  (The use case for non-readonly `RANDOM` is setting a known seed to get
  reproducible pseudorandom sequences. To get that in a modernish script,
  use `awk`'s `srand(yourseed)` and `int(rand()*32768)`.)
* `LINENO`: the `$LINENO` variable contains the current shell script line
  number.
* *`LOCAL`*: function-local variables, either using the `local` keyword, or
  by aliasing `local` to `typeset` (mksh, yash).
* *`KSH88FUNC`*: define ksh88-style shell functions with the 'function' keyword,
  supporting dynamically scoped local variables with the 'typeset' builtin.
  (mksh, bash, zsh, yash, et al)
* *`KSH93FUNC`*: the same, but with static scoping for local variables. (ksh93 only)
  See Q28 at the [ksh93 FAQ](http://kornshell.com/doc/faq.html) for an explanation
  of the difference.
* `ARITHPP`: support for the `++` and `--` unary operators in shell arithmetic.
* `ARITHCMD`: standalone arithmetic evaluation using a command like
  `((`*expression*`))`.
* `ARITHFOR`: ksh93/C-style arithmetic 'for' loops of the form
  `for ((`*exp1*`; `*exp2*`; `*exp3*`)) do `*commands*`; done`.
* `CESCQUOT`: Quoting with C-style escapes, like `$'\n'` for newline.
* `ADDASSIGN`: Add a string to a variable using additive assignment,
  e.g. *VAR*`+=`*string*
* `PSREPLACE`: Search and replace strings in variables using special parameter
  substitutions with a syntax vaguely resembling sed.
* `ROFUNC`: Set functions to read-only with `readonly -f`. (bash, yash)
* `DOTARG`: Dot scripts support arguments.
* `HERESTR`: Here-strings, an abbreviated kind of here-document.
* `TESTO`: The `test`/`[` builtin supports the `-o` unary operator to check if 
  a shell option is set.
* `PRINTFV`: The shell's `printf` builtin has the `-v` option to print to a variable,
  which avoids forking a command substitution subshell.
* `ANONFUNC`: zsh anonymous functions (basically the native zsh equivalent
  of modernish's var/setlocal module)
* `KSHARRAY`: ksh88-style arrays. Supported on bash, zsh (under `emulate sh`),
  mksh, pdksh and ksh93.
* `KSHARASGN`: ksh93-style mass array assignment in the style of
  `array=(one two three)`. Supported on the same shells as KSHARRAY except pdksh.
* `TRAPZERR`: This feature ID is detected if the `ERR` trap is an alias for
  the `ZERR` trap. According to the zsh manual, this is the case for zsh on
  most systems, i.e. those that don't have a `SIGERR` signal. (The
  [trap stack](#user-content-the-trap-stack)
  uses this feature test.)
* `TRAPPRSUBSH`: The ability to obtain a list of the current shell's native
  traps from a command substitution subshell, for example: `var=$(trap)`.
  Note that modernish transparently reimplements this feature on shells
  without this native capability, so this feature ID is only relevant if you
  are bypassing modernish to access the `trap` builtin directly. Also, in
  order to be useful to modernish, this feature test only yields a positive
  if the `trap` command in `var=$(trap)` can be replaced by a shell function
  that in turn calls the builtin `trap` command.
* `OPTNOPREFIX`: Long-form shell option names use a dynamic `no` prefix for
  all options (including POSIX ones). For instance, `glob` is the opposite
  of `noglob`, and `nonotify` is the opposite of `notify`. (ksh93, yash, zsh)

### Quirks ###

Shell quirks currently tested for are:

* *`QRK_IFSFINAL`*: in field splitting, a final non-whitespace IFS delimiter
  character is counted as an empty field (yash \< 2.42, zsh, pdksh). This is a QRK
  (quirk), not a BUG, because POSIX is ambiguous on this.
* `QRK_32BIT`: mksh: the shell only has 32-bit arithmetics. Since every modern
  system these days supports 64-bit long integers even on 32-bit kernels, we
  can now count this as a quirk.
* `QRK_APIPEMAIN`: On zsh \< 5.3, any element of a pipeline (not just the
  last element) that is nothing but a simple variable assignment is executed
  in the current shell environment, instead of a subshell. For instance, the
  assignment `var=foo` survives `SomeCommands | var=foo | SomeMoreCommands`.
* `QRK_ARITHEMPT`: In yash, with POSIX mode turned off, a set but empty
  variable yields an empty string when used in an arithmetic expression,
  instead of 0. For example, `foo=''; echo $((foo))` outputs an empty line.
* `QRK_ARITHWHSP`: In [yash](https://osdn.jp/ticket/browse.php?group_id=3863&tid=36002)
  and FreeBSD /bin/sh, trailing whitespace from variables is not trimmed in arithmetic
  expansion, causing the shell to exit with an 'invalid number' error. POSIX is silent
  on the issue. The modernish `isint` function (to determine if a string is a valid
  integer number in shell syntax) is `QRK_ARITHWHSP` compatible, tolerating only
  leading whitespace.
* `QRK_BCDANGER`: `break` and `continue` can affect non-enclosing loops,
  even across shell function barriers (zsh, Busybox ash; older versions
  of bash, dash and yash). (This is especially dangerous when using
  [var/setlocal](#user-content-use-varsetlocal)
  which internally uses a temporary shell function to try to protect against
  breaking out of the block without restoring global parameters and settings.)
* `QRK_EMPTPPFLD`: Unquoted `$@` and `$*` do not discard empty fields.
  [POSIX says](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_05_02)
  for both unquoted `$@` and unquoted `$*` that empty positional parameters
  *may* be discarded from the expansion. AFAIK, just one shell (yash)
  doesn't.
* `QRK_EMPTPPWRD`: [POSIX says](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_05_02)
  that empty `"$@"` generates zero fields but empty `''` or `""` or
  `"$emptyvariable"` generates one empty field. But it leaves unspecified
  whether something like `"$@$emptyvariable"` generates zero fields or one
  field. Zsh, pdksh/mksh and (d)ash generate one field, as seems logical.
  But bash, AT&T ksh and yash generate zero fields, which we consider a
  quirk. (See also BUG_PP_01)
* `QRK_EVALNOOPT`: `eval` does not parse options, not even `--`, which makes it
  incompatible with other shells: on the one hand, (d)ash does not accept   
  `eval -- "$command"` whereas on other shells this is necessary if the command
  starts with a `-`, or the command would be interpreted as an option to `eval`.
  A simple workaround is to prefix arbitrary commands with a space.
  [Both situations are POSIX compliant](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_19_16),
  but since they are incompatible without a workaround,the minority situation
  is labeled here as a QuiRK.
* `QRK_EXECFNBI`: In pdksh and zsh, `exec` looks up shell functions and
  builtins before external commands, and if it finds one it does the
  equivalent of running the function or builtin followed by `exit`. This
  is probably a bug in POSIX terms; `exec` is supposed to launch a
  program that overlays the current shell, implying the program launched by
  `exec` is always external to the shell. However, since the
  [POSIX language](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_20)
  is rather
  [vague and possibly incorrect](https://www.mail-archive.com/austin-group-l@opengroup.org/msg01437.html),
  this is labeled as a shell quirk instead of a shell bug.
* `QRK_HDPARQUOT`: Double **quot**es within certain **par**ameter substitutions in
  **h**ere-**d**ocuments aren't removed (FreeBSD sh; bosh). For instance, if
  `var` is set, `${var+"x"}` in a here-document yields `"x"`, not `x`.
  [POSIX considers it undefined](https://www.mail-archive.com/austin-group-l@opengroup.org/msg01626.html)
  to use double quotes there, so they should be avoided for a script to be
  fully POSIX compatible.
  (Note this quirk does **not** apply for substitutions that remove pattens,
  such as `${var#"$x"}` and `${var%"$x"}`; those are defined by POSIX
  and double quotes are fine to use.)
  (Note 2: single quotes produce widely varying behaviour and should never
  be used within any form of parameter substitution in a here-document.)
* `QRK_LOCALINH`: On a shell with LOCAL, local variables, when declared
  without assigning a value, inherit the state of their global namesake, if
  any. (dash, FreeBSD sh)
* `QRK_LOCALSET`: On a shell with LOCAL, local variables are immediately set
  to the empty value upon being declared, instead of being initially without
  a value. (zsh)
* `QRK_LOCALSET2`: Like `QRK_LOCALSET`, but *only* if the variable by the
  same name in the global/parent scope is unset. If the global variable is
  set, then the local variable starts out unset. (bash 2 and 3)
* `QRK_LOCALUNS`: On a shell with LOCAL, local variables lose their local
  status when unset. Since the variable name reverts to global, this means that
  *`unset` will not necessarily unset the variable!* (yash, pdksh/mksh. Note:
  this is actually a behaviour of `typeset`, to which modernish aliases `local`
  on these shells.)
* `QRK_LOCALUNS2`: This is a more treacherous version of `QRK_LOCALUNS` that
  is unique to bash. The `unset` command works as expected when used on a local
  variable in the same scope that variable was declared in, **however**, it
  makes local variables global again if they are unset in a subscope of that
  local scope, such as a function called by the function where it is local.
  (Note: since `QRK_LOCALUNS2` is a special case of `QRK_LOCALUNS`, modernish
  will not detect both.)
* `QRK_OPTCASE`: Long-form shell option names are case-insensitive. (yash, zsh)
* `QRK_OPTDASH`: Long-form shell option names ignore the `-`. (ksh93, yash)
* `QRK_OPTULINE`: Long-form shell option names ignore the `_`. (yash, zsh)
* `QRK_PPIPEMAIN`: On zsh, in all elements of a pipeline, parameter
  expansions are evaluated in the current environment (with any changes they
  make surviving the pipeline), though the commands themselves of every
  element but the last are executed in a subshell. For instance, given unset
  or empty `v`, in the pipeline `cmd1 ${v:=foo} | cmd2`, the assignment to
  `v` survives, though `cmd1` itself is executed in a subshell.
* `QRK_SPCBIXP`: Variable assignments directly preceding
  [special builtin commands](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_14)
  are exported, and persist as exported. (bash; yash)
* `QRK_UNSETF`: If 'unset' is invoked without any option flag (-v or -f), and
  no variable by the given name exists but a function does, the shell unsets
  the function. (bash)


### Bugs ###

Non-fatal shell bugs currently tested for are:

* `BUG_APPENDC`: When `set -C` (`noclobber`) is active, "appending" to a nonexistent
  file with `>>` throws an error rather than creating the file. (zsh \< 5.1)
  This is a bug making `use safe` less convenient to work with, as this sets
  the `-C` (`-o noclobber`) option to reduce accidental overwriting of files.
  The `safe` module requires an explicit override to tolerate this bug.
* `BUG_ARITHINIT`: Using unset or empty variables (dash <= 0.5.9.1)
  or unset variables (yash <= 2.44) in arithmetic expressions causes the
  shell to exit, instead of taking them as a value of zero.
* `BUG_ARITHLNNO`: The shell supports `$LINENO`, but the variable is
   considered unset in arithmetic contexts, like `$(( LINENO > 0 ))`.
   This makes it error out under `set -u` and default to zero otherwise.
   Workaround: use shell expansion like `$(( $LINENO > 0 ))`. (FreeBSD sh)
* `BUG_ARITHSPLIT`: Unquoted `$((`arithmetic expressions`))` are not
  subject to field splitting as expected. (zsh, pdksh, mksh<=R49)
* `BUG_ARITHTYPE`: In zsh, arithmetic assignments (using `let`, `$(( ))`,
  etc.) on unset variables assign a numerical/arithmetic type to a variable,
  causing subsequent normal variable assignments to be interpreted as
  arithmetic expressions and fail if they are not valid as such.
* `BUG_BRACQUOT`: shell quoting within bracket patterns has no effect (zsh < 5.3;
  ksh93) This bug means the `-` retains it special meaning of 'character
  range', and an initial `!` (and, on some shells, `^`) retains the meaning of
  negation, even in quoted strings within bracket patterns, including quoted
  variables.
* `BUG_CASECC`: glob patterns as in `case` cannot match an escaped `^A`
  (`$CC01`) or `DEL` (`$CC7F`) control character. Found on: bash 2.05b, 3.0, 3.1
* `BUG_CASELIT`: If a `case` pattern doesn't match as a pattern, it's tried
  again as a literal string, even if the pattern isn't quoted. This can
  result in false positives when a pattern doesn't match itself, like with
  bracket patterns. This contravenes POSIX and breaks use cases such as
  input validation. (AT&T ksh93) Note: modernish `match` works around this.
* `BUG_CASESTAT`: The 'case' conditional construct prematurely clobbers the
  exit status `$?`. (found in zsh \< 5.3, Busybox ash \<= 1.25.0, dash \<
  0.5.9.1)
* `BUG_CC7F`: Quoted expansions delete the DEL control character (`$CC7F`),
  except if that character is directly preceded in the value by the `\1`
  (`$CC01`) control character. Note that this bug removes DEL from
  `$CONTROLCHARS` and `$ASCIICHARS`. (bash 2.05b, 3.0)
* `BUG_CMDOPTEXP`: the `command` builtin does not recognise options if they
  result from expansions. For instance, you cannot conditionally store `-p`
  in a variable like `defaultpath` and then do `command $defaultpath
  someCommand`. (found in zsh \< 5.3)
* `BUG_CMDPV`: `command -pv` does not find builtins ({pd,m}ksh), does not
  accept the -p and -v options together (zsh \< 5.3) or ignores the '-p'
  option altogether (bash 3.2); in any case, it's not usable to find commands
  in the default system PATH.
* *`BUG_CMDSPASGN`*: preceding a
  [special builtin](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_14)
  with 'command' does not stop
  preceding invocation-local variable assignments from becoming global.
  (AT&T ksh, 2010-ish versions; bash 2.05b and 3.0 in POSIX mode have a variant
  of this bug that only applies to the `eval`, `.`, and `source` builtins)
* `BUG_CMDSPEXIT`: preceding a
  [special builtin](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_14)
  with 'command' does not stop
  it from exiting the shell if the builtin encounters error.
  (zsh \< 5.2; mksh \< R50e)
* `BUG_CMDVRESV`: 'command -v' does not find reserved words such as "if".
  (pdksh, mksh). This necessitates a workaround version of thisshellhas().
* `BUG_CSCMTQUOT`: unbalanced single and double quotes and backticks in comments
  within command substitutions cause obscure and hard-to-trace syntax errors
  later on in the script. (ksh88; pdksh, incl. {Open,Net}BSD ksh; bash 2.05b)
* `BUG_CSNHDBKSL`: Backslashes within non-expanding here-documents within
  command substitutions are incorrectly expanded to perform newline joining,
  as opposed to left intact. (bash \<= 4.4, and pdksh)
* `BUG_DOLRCSUB`: parsing problem where, inside a command substitution of
  the form `$(...)`, the sequence `$$'...'` is treated as `$'...'` (i.e. as
  a use of CESCQUOT), and `$$"..."` as `$"..."` (bash-specific translatable
  string). (Found in bash up to 4.4)
* `BUG_DQGLOB`: *glob*bing is not properly deactivated within
  *d*ouble-*q*uoted strings. Within double quotes, a `*` or `?` immediately
  following a backslash is interpreted as a globbing character. This applies
  to both pathname expansion and pattern matching in `case`. Found in: dash.
  (The bug is not triggered when using modernish
  [`match`](#user-content-string-tests).)
* `BUG_EMPTYBRE` is a `case` pattern matching bug in zsh < 5.0.8: empty
  bracket expressions eat subsequent shell grammar, producing unexpected
  results. This is particularly bad if you want to pass a bracket
  expression using a variable or parameter, and that variable or parameter
  could be empty. This means the grammar parsing depends on the contents
  of the variable!
* `BUG_EVALCOBR`: `break` and `continue` do not work if they are within `eval`.
  (pdksh; mksh \< R55 2017/04/12; a variant exists on FreeBSD sh \< 10.3)
* `BUG_FNREDIRP`: I/O redirections on function definitions are forgotten if the
  function is called as part of a pipeline with at least one `|`. (bash 2.05b)
* `BUG_FNSUBSH`: Function definitions within subshells (including command
  substitutions) are ignored if a function by the same name exists in the
  main shell, so the wrong function is executed. `unset -f` is also silently
  ignored. ksh93 (all current versions as of November 2018) has this bug.
  It only applies to non-forked subshells. Workaround: force the subshell
  to fork with `ulimit -t unlimited 2>/dev/null`.
* `BUG_HASHVAR`: On zsh, `$#var` means the length of `$var` - other shells and
  POSIX require braces, as in `${#var}`. This causes interesting bugs when
  combining `$#`, being the number of positional parameters, with other
  strings. For example, in arithmetics: `$(($#-1))`, instead of the number of
  positional parameters minus one, is interpreted as `${#-}` concatenated with
  `1`. So, for zsh compatibility, always use `${#}` instead of `$#` unless it's
  stand-alone or followed by a space.
* `BUG_HDOCBKSL`: Line continuation using *b*ac*ksl*ashes in expanding
  *h*ere-*doc*uments is handled incorrectly. (zsh up to 5.4.2)
* `BUG_HDOCMASK`: Here-documents (and here-strings, see `HERESTRING`) use
  temporary files. This fails if the current `umask` setting disallows the
  user to read, so the here-document can't read from the shell's temporary
  file. Workaround: ensure user-readable `umask` when using here-documents.
  (bash, pdksh, mksh, zsh)
* `BUG_IFSGLOBC`: In glob pattern matching (such as in `case` and `[[`), if a
  wildcard character is part of `IFS`, it is matched literally instead of as a
  matching character. This applies to glob characters `*`, `?`, `[` and `]`.
  *Since nearly all modernish functions use `case` for argument validation and
  other purposes, nearly every modernish function breaks on shells with this
  bug if IFS contains any of these three characters!*
  (Found in bash \< 4.4)
* `BUG_IFSGLOBP`: In pathname expansion (filename globbing), if a
  wildcard character is part of `IFS`, it is matched literally instead of as a
  matching character. This applies to glob characters `*`, `?`, `[` and `]`.
  (Bug found in bash, all versions up to at least 4.4)
* `BUG_IFSGLOBS`: in glob pattern matching (as in `case` or paramter
  substitution with `#` and `%`), if `IFS` starts with `?` or `*` and the
  `"$*"` parameter expansion inserts any IFS separator characters, those
  characters are erroneously interpreted as wildcards when quoted "$*" is
  used as the glob pattern. (AT&T ksh93)
* *`BUG_IFSISSET`*: AT&T ksh93 (recent versions): `${IFS+s}` always yields 's'
  even if IFS is unset. This applies to IFS only.
* `BUG_ISSETLOOP`: AT&T ksh93: Expansions like `${var+set}`
  remain static when used within a `for`, `while` or
  `until` loop; the expansions don't change along with the state of the
  variable, so they cannot be used to check whether a variable is set
  within a loop if the state of that variable may change
  in the course of the loop.
* `BUG_KUNSETIFS`: ksh93: Can't unset `IFS` under very specific
  circumstances. `unset -v IFS` is a known POSIX shell idiom to activate
  default field splitting. With this bug, the `unset` builtin silently fails
  to unset IFS (i.e. fails to activate field splitting) if we're executing
  an `eval` or a trap and a number of specific conditions are met. See
  [BUG_KUNSETIFS.t](https://github.com/modernish/modernish/blob/master/libexec/modernish/cap/BUG_KUNSETIFS.t)
  for more information.
* `BUG_LNNOALIAS`: The shell has LINENO, but $LINENO is always expanded to 0
  when used within an alias. (pdksh variants, including mksh and oksh)
* `BUG_LNNOEVAL`: The shell has LINENO, but $LINENO is always expanded to 0
  when used in 'eval'. (pdksh variants, including mksh and oksh)
* `BUG_MULTIBIFS`: We're on a UTF-8 locale and the shell supports UTF-8
  characters in general (i.e. we don't have `BUG_MULTIBYTE`) -- however, using
  multibyte characters as `IFS` field delimiters still doesn't work. For
  example, `"$*"` joins positional parameters on the first byte of `$IFS`
  instead of the first character. (ksh93, mksh, FreeBSD sh, Busybox ash)
* *`BUG_MULTIBYTE`*: We're in a UTF-8 locale but the shell does not have
  multi-byte/variable-length character support. (Non-UTF-8 variable-length
  locales are not yet supported.) Dash is a recent shell with this bug.
* `BUG_NOCHCLASS`: POSIX-mandated character `[:`classes`:]` within bracket
  `[`expressions`]` are not supported in glob patterns. (pdksh, mksh, and
  family)
* `BUG_NOEXPRO`: Cannot export read-only variables. (zsh 5.0.8-5.5.1 as sh)
* *`BUG_NOOCTAL`*: Shell arithmetic does interpret numbers with leading
  zeroes as octal numbers; these are interpreted as decimal instead,
  though POSIX specifies octal. (older mksh, 2013-ish versions)
* `BUG_NOUNSETEX`: Cannot assign export attribute to variables in an unset
  state; exporting a variable immediately sets it to the empty value.
  (zsh \< 5.3)
* `BUG_NOUNSETRO`: Cannot freeze variables as readonly in an unset state.
  This bug in zsh \< 5.0.8 makes the `readonly` command set them to the
  empty string instead.
* `BUG_OPTNOLOG`: on dash, setting `-o nolog` causes `$-` to wreak havoc:
  trying to expand `$-` silently aborts parsing of an entire argument,
  so e.g. `"one,$-,two"` yields `"one,"`. (Same applies to `-o debug`.)
* *`BUG_PARONEARG`*: When `IFS` is empty on bash 3.x and 4.x (i.e. field
  splitting is off), `${1+"$@"}` is counted as a single argument instead
  of each positional parameter as separate arguments. To avoid this bug,
  simply use `"$@"` instead. (`${1+"$@"}` is an obsolete workaround for
  a fatal shell bug, `FTL_UPP`.)
* `BUG_PFRPAD`:  Negative padding value for strings in the `printf` builtin
  does not cause blank padding on the right-hand side, but inserts blank
  padding on the left-hand side as if the value were positive, e.g.
  `printf '[%-4s]' hi` outputs `[  hi]`, not `[hi  ]`. (zsh 5.0.8)
* `BUG_PP_01`: [POSIX says](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_05_02)
  that empty `"$@"` generates zero fields but empty `''` or `""` or
  `"$emptyvariable"` generates one empty field. This means concatenating
  `"$@"` with one or more other, separately quoted, empty strings (like
  `"$@""$emptyvariable"`) should still produce one empty field. But on
  bash 3.x, this erroneously produces zero fields. (See also QRK_EMPTPPWRD)
* `BUG_PP_02`: Like `BUG_PP_01`, but with unquoted `$@` and only
  with `"$emptyvariable"$@`, not `$@"$emptyvariable"`. (pdksh)
* `BUG_PP_03`: When IFS is unset or empty (zsh 5.3.1) or empty (pdksh),
  assigning `var=$*` only assigns the first field, failing to join and
  discarding the rest of the fields. Workaround: `var="$*"`
  (POSIX leaves `var=$@`, etc. undefined, so we don't test for those.)
* `BUG_PP_03A`: When IFS is unset, assignments like `var=$*`
  incorrectly remove leading and trailing spaces (but not tabs or
  newlines) from the result. Workaround: quote the expansion. Found on:
  bash 4.3 and 4.4.
* `BUG_PP_03B`: When IFS is unset, assignments like `var=${var+$*}`,
  etc. incorrectly remove leading and trailing spaces (but not tabs or
  newlines) from the result. Workaround: quote the expansion. Found on:
  bash 4.3 and 4.4.
* `BUG_PP_03C`: When `IFS` is unset, assigning `var=${var-$*}` only assigns
  the first field, failing to join and discarding the rest of the fields.
  (zsh 5.3, 5.3.1) Workaround: `var=${var-"$*"}`
* `BUG_PP_04`: If IFS is set and empty, assigning the positional parameters
  to a variable using a conditional assignment within a parameter substitution,
  such as `: ${var=$*}`, discards everything but the last field from the
  assigned value while incorrectly generating multiple fields for the
  expansion. (pdksh, mksh)
* `BUG_PP_04_S`: When IFS is null (empty), the result of a substitution
  like `${var=$*}` is incorrectly field-split on spaces. The difference
  with BUG_PP_04 is that the assignment itself succeeds normally.
  Found on: bash 4.2, 4.3
* `BUG_PP_04A`: Like BUG_PP_03A, but for conditional assignments within
  parameter substitutions, as in `: ${var=$*}` or `: ${var:=$*}`.
  Workaround: quote either `$*` within the expansion or the expansion
  itself. Found on: bash 2.05b through 4.4.
* `BUG_PP_04B`: When assigning the positional parameters ($*) to a variable
  using a conditional assignment within a parameter substitution, e.g.
  `: ${var:=$*}`, the fields are always joined and separated by spaces,
  regardless of the content or state of IFS. Workaround as in BUG_PP_04A.
  (bash 2.05b)
* `BUG_PP_04D`: When field-splitting the result of an expansion such
  as `${var:=$*}`, if the first positional parameter starts with a space,
  an initial empty field is incorrectly generated. (mksh <= R50)
* `BUG_PP_04E`: Like `BUG_PP_04B` but not if IFS is set and empty. (bash 4.3)
* `BUG_PP_05`: [POSIX says](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_05_02)
  that empty `$@` and `$*` generate zero fields, but with null IFS, empty
  unquoted `$@` and `$*` yield one empty field. Found on: dash 0.5.9
  and 0.5.9.1; Busybox ash.
* `BUG_PP_06`: [POSIX says](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_05_02)
  that unquoted `$@` initially generates as many fields as there are
  positional parameters, and then (because `$@` is unquoted) each field is
  split further according to `IFS`. With this bug, the latter step is not
  done. Found on: zsh \< 5.3
* `BUG_PP_06A`: [POSIX says](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_05_02)
  that unquoted `$@` and `$*` initially generate as many fields as there are
  positional parameters, and then (because `$@` or `$*` is unquoted) each field is
  split further according to `IFS`. With this bug, the latter step is not
  done if `IFS` is unset (i.e. default split). Found on: zsh \< 5.4
* `BUG_PP_07`: unquoted `$*` and `$@` (including in substitutions like
  `${1+$@}` or `${var-$*}`) do not perform default field splitting if
  `IFS` is unset. Found on: zsh (up to 5.3.1) in sh mode
* `BUG_PP_07A`: When `IFS` is unset, unquoted `$*` undergoes word splitting
  as if `IFS=' '`, and not the expected `IFS=" ${CCt}${CCn}"`.
  Found on: bash 4.4
* `BUG_PP_08`: When `IFS` is empty, unquoted `$@` and `$*` do not generate
  one field for each positional parameter as expected, but instead join
  them into a single field without a separator. Found on: yash \< 2.44
  and dash \< 0.5.9 and Busybox ash \< 1.27.0
* `BUG_PP_08B`: When `IFS` is empty, unquoted `$*` within a substitution (e.g.
  `${1+$*}` or `${var-$*}`) does not generate one field for each positional
  parameter as expected, but instead joins them into a single field without
  a separator. Found on: bash 3 and 4
* `BUG_PP_09`: When `IFS` is non-empty but does not contain a space,
  unquoted `$*` within a substitution (e.g. `${1+$*}` or `${var-$*}`) does
  not generate one field for each positional parameter as expected,
  but instead joins them into a single field separated by spaces
  (even though, as said, IFS does not contain a space).
  Found on: bash 2
* `BUG_PP_10`: When `IFS` is null (empty), assigning `var=$*` removes any
  `$CC01` (^A) and `$CC7F` (DEL) characters. (bash 3, 4)
* `BUG_PP_10A`: When `IFS` is non-empty, assigning `var=$*` prefixes each
  `$CC01` (^A) and `$CC7F` (DEL) character with a `$CC01` character. (bash 4.4)
* `BUG_PP_11`: If `IFS` is set and empty (no field separator for `$*`),
  assigning unquoted `$*` to a variable (i.e.: `foo=$*`) causes the fields
  to be separated by a space in the variable, instead of joined together
  without a separator. (bash 2.05b, 3.0)
* `BUG_PSUBBKSL1`: A backslash-escaped `}` character within a quoted parameter
  substitution is not unescaped. (bash 2 & 3, standard dash, Busybox ash)
* `BUG_PSUBNEWLN`: Due to a bug in the parser, parameter substitutions
  spread over more than one line cause a syntax error.
  Workaround: instead of a literal newline, use [`$CCn`](#user-content-control-character-whitespace-and-shell-safe-character-constants).
  (found in dash \<= 0.5.9.1 and Busybox ash \<= 1.28.1)
* `BUG_PSUBSQUOT`: in pattern matching parameter substitutions
  (`${param#pattern}`, `${param%pattern}`, `${param##pattern}` and
  `${param%%pattern}`), if the whole parameter substitution is quoted with
  double quotes, then single quotes in the *pattern* are not parsed. POSIX
  [says](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_06_02)
  they are to keep their special meaning, so that glob characters may
  be quoted. For example: `x=foobar; echo "${x#'foo'}"` should yield `bar`
  but with this bug yields `foobar`. (dash; Busybox ash)
* `BUG_PSUBSQHD`: Like BUG_PSUBSQUOT, but included a here-document instead of
  quoted with double quotes. (dash, pdksh, mksh)
* `BUG_READWHSP`: If there is more than one field to read, `read` does not
   trim trailing IFS whitespace (dash 0.5.7, 0.5.8) or any IFS whitespace
   (dash 0.5.6, 0.5.6.1).
* `BUG_REDIRIO`: the I/O redirection operator `<>` (open a file descriptor
  for both read and write) defaults to opening standard output (i.e. is
  short for `1<>`) instead of defaulting to opening standard input (`0<>`) as
  [POSIX specifies](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_07_07).
  (AT&T ksh93)
* `BUG_REDIRPOS`: Buggy behaviour occurs if a *redir*ection is *pos*itioned
  in between to variable assignments in the same command. On zsh 5.0.x, a
  parse error is thrown. On zsh 5.1 to 5.4.2, anything following the
  redirection (other assignments or command arguments) is silently ignored.
* `BUG_SCLOSEDFD`: bash \< 5.0 and dash \<= 0.5.9.1 fail to save a closed file
  descriptor onto the shell-internal stack when added at the end of a block or
  loop (e.g. `} 8<&-` or `done 7>&-`), so any 'exec' of that descriptor will
  leak out of the block. However, pushing an open file descriptor works fine.
  Workaround: enclose in another block that pushes the FD in an open state.
* `BUG_SELECTEOF`: in a shell-native 'select' loop, the REPLY variable
  is not cleared if the user presses Ctrl-D to exit the loop. (zsh)
* `BUG_SELECTRPL`: in a shell-native 'select' loop, input that is not a menu
  item is not stored in the REPLY variable as it should be. (mksh R50 2014)
* `BUG_SETOUTVAR`: The `set` builtin (with no arguments) only prints native
  function-local variables when called from a shell function. (yash \<= 2.46)
* `BUG_SPCBILOC`: Variable assignments preceding
  [special builtins](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_14)
  create a partially function-local variable if a variable by the same name
  already exists in the global scope. (bash \< 5.0 in POSIX mode)
* `BUG_TESTERR0`: mksh: `test`/`[` exits successfully (exit status 0) if
  an invalid argument is given to an operator. (mksh R52 fixes this)
* `BUG_TESTERR1A`: AT&T ksh: `test`/`[` exits with a non-error 'false' status
  (1) if an invalid argument is given to an operator.
* `BUG_TESTERR1B`: zsh: `test`/`[` exits with status 1 (false) if there are
  too few or too many arguments, instead of a status > 1 as it should do.
* `BUG_TESTILNUM`: On dash (up to 0.5.8), giving an illegal number to `test -t`
  or `[ -t` causes some kind of corruption so the next `test`/`[` invocation
  fails with an "unexpected operator" error even if it's legit.
* `BUG_TESTONEG`: The `test`/`[` builtin supports a `-o` unary operator to
  check if a shell option is set, but it ignores the `no` prefix on shell
  option names, so something like `[ -o noclobber ]` gives a false positive.
  Bug found on yash up to 2.43. (The `TESTO` feature test implicitly checks
  against this bug and won't detect the feature if the bug is found.)
* `BUG_TESTPAREN`: Incorrect exit status of `test -n`/`-z` with values `(`,
  `)` or `!` in zsh 5.0.6 and 5.0.7. This can make scripts that process
  arbitrary data (e.g. the shellquote function) take the wrong action unless
  workarounds are implemented or modernish equivalents are used instead.
  Also, spurious error message with both `test -n` and `test -z`.
* `BUG_TESTRMPAR`: zsh: in binary operators with `test`/`[`, if the first
  argument starts with `(` and the last with `)', both the first and the
  last argument are completely removed, leaving only the operator, and the
  result of the operation is incorrectly true because the operator is
  incorrectly parsed as a non-empty string. This applies to any operator.
* `BUG_TRAPEMPT`: The `trap` builtin does not quote empty traps in its
  output, rendering the output unsuitable for shell re-input. For instance,
  `trap '' INT; trap` outputs "`trap --  INT`" instead of "`trap -- '' INT`".
  (found in pdksh, mksh)
* `BUG_TRAPEXIT`: the shell's `trap` builtin does not know the EXIT trap by
  name, but only by number (0). Using the name throws a "bad trap" error. Found in
  [klibc 2.0.4 dash](https://git.kernel.org/pub/scm/libs/klibc/klibc.git/tree/usr/dash).
  Note that the modernish `trap` and `pushtrap` commands effectively work
  around this bug, so it only affects scripts if they bypass modernish.
* `BUG_TRAPRETIR`: Using 'return' within 'eval' triggers infinite recursion if
  both a RETURN trap and the 'functrace' shell option are active. This bug in
  bash-only functionality triggers a crash when using modernish, so to avoid
  this, modernish automatically disables the `functrace` shell option if a
  `RETURN` trap is set or pushed and this bug is detected. (bash 4.3, 4.4)
* `BUG_XTRCREDIR`: When xtrace (`set -x`) is active, redirections are applied
  before the command's trace is printed to standard error, so that something
  like `command 2>&1` outputs the trace to standard output instead of
  standard error. This can interfere with command substitutions like
  `var=$(command 2>&1)`. (yash \<= 2.47)


### Warning IDs ###

Warning IDs do not identify any characteristic of the shell, but instead
warn about a potentially problematic system condition that was detected at
initalisation time.

* *`WRN_2UP2LOW`*: This warning ID is issued if modernish is initialised
  in a UTF-8 locale and the modernish functions
  [`toupper` and `tolower`](#user-content-touppertolower)
  cannot convert non-ASCII letters to upper or lower case -- e.g. accented
  Latin letters, Greek, cyrillic. Modernish tries hard to make it work,
  falling back to using the external `tr`, `awk`, `gawk` or GNU `sed`
  command if the shell can't convert non-ASCII (or any) characters itself.
  So if the shell cannot do it, then this warning ID is only issued if none
  of these external commands can convert them either. But if the shell can,
  then this warning ID is not issued even if the external commands cannot.
  This means that *the result of `thisshellhas WRN_2UP2LOW`* ***only***
  *applies to the modernish `toupper` and `tolower` functions* and not to
  your shell or any external command in particular.
* *`WRN_NOSIGPIPE`*: Modernish has detected that the process that launched
  the current program has set `SIGPIPE` to ignore, an irreversible condition
  that is in turn inherited by any process started by the current shell, and
  their subprocesses, and so on. This makes it impossible to detect
  [`$SIGPIPESTATUS`](#user-content-modernish-system-constants);
  it is set to the special
  value 99999 which is impossible as an exit status. But it also makes it
  irrelevant what that status is, because neither the current shell nor any
  process it spawns is now capable of receiving `SIGPIPE`. The
  [`-P` option to `harden`](#hardening-while-allowing-for-broken-pipes)
  is also rendered irrelevant. Note that a command such as `yes | head -n
  10` now never ends; the only way `yes` would ever stop trying to write
  lines is by receiving `SIGPIPE` from `head`, which is being ignored.
  Programs that use commands in this fashion should check `if thisshellhas
  WRN_NOSIGPIPE` and either employ workarounds or refuse to run if so.


## Appendix B ##

Modernish comes with a suite of regression tests to detect bugs in modernish
itself, which can be run using `modernish --test` after installation. By
default, it will run all the tests verbosely but without tracing the command
execution. The `install.sh` installer will run the suite quietly on the
selected shell before installation.

A few options are available to specify after `--test`:

* `-e`: run expensive (i.e. slow or memory-hogging) tests that are disabled
  by default. Some tests run without this option but are more thorough
  if this option is given.
* `-q`: quieter operation; report expected fails [known shell bugs]
  and unexpected fails [bugs in modernish]). Add `-q` again for
  quietest operation (report unexpected fails only).
* `-s`: entirely silent operation.
* `-t`: run only specific test sets or tests. Test sets are those listed
  in the full default output of `modernish --test`. This option requires
  an option-argument in the following format:    
  *testset1*`:`*num1*`,`*num2*`,`…`/`*testset2*`:``*num1*`,`*num2*`,`…`/`…    
  The colon followed by numbers is optional; if omitted, the entire set
  will be run, otherwise the given numbered tests will be run in the given
  order. Example: `modernish --test -t match:2,4,7/arith/shellquote:1` runs
  test 2, 4 and 7 from the `match` set, the entire `arith` set, and only
  test 1 from the `shellquote` set.
* `-x`: trace each test using the shell's `xtrace` facility. Each trace is
  stored in a separate file in a specially created temporary directory. By
  default, the trace is deleted if a test does not produce an unexpected
  fail. Add `-x` again to keep expected fails as well, and again to
  keep all traces regardless of result. If any traces were saved,
  modernish will tell you the location of the temporary directory at the
  end, otherwise it will silently remove the directory again.

These short options can be combined so, for example,
`--test -qxx` is the same as `--test -q -x -x`.

### Difference between bug/quirk/feature tests and regression tests ###

Note the difference between these regression tests and the tests listed
above in [Appendix A](#user-content-appendix-a). The latter are tests for
whatever shell is executing modernish: they test for capabilities (features,
quirks, bugs) of the current shell. They are meant to be run via
[`thisshellhas`](#user-content-feature-testing) and are designed to be
taken advantage of in scripts. On the other hand, these tests run by
`modernish --test` are regression tests for modernish itself. It does not
make sense to use these in a script.

New/unknown shell bugs can still cause modernish regression tests to fail,
of course. That's why some of the regression tests also check for
consistency with the results of the feature/quirk/bug tests: if there is a
shell bug in a widespread release version that modernish doesn't know about
yet, this in turn is considered to be a bug in modernish, because one of its
goals is to know about all the shell bugs in all released shell versions
currently seeing significant use.

### Testing modernish on all your shells ###

The `testshells.sh` program in `share/doc/modernish/examples` can be used to
run the regression test suite on all the shells installed on your system.
You could put it as `testshells` in some convenient location in your
`$PATH`, and then simply run:

    testshells modernish --test

(adding any further options you like -- for instance, you might like to add
`-q` to avoid very long terminal output). On first run, `testshells` will
generate a list of shells it can find on your system and it will give you a
chance to edit it before proceeding.

---

`EOF`
