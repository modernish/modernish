<p align="center"><strong>For code examples, see
<a href="https://github.com/modernish/modernish/blob/master/EXAMPLES.md">
<code>EXAMPLES.md</code></a>
and
<a href="https://github.com/modernish/modernish/tree/master/share/doc/modernish/examples">
<code>share/doc/modernish/examples</code></a>
</strong></p>

# modernish – harness the shell #

-   *Sick of quoting hell and split/glob pitfalls?*
-   *Tired of brittle shell scripts going haywire and causing damage?*
-   *Mystified by line noise commands like `[`, `[[`, `((` ?*
-   *Is scripting basic things just too hard?*
-   *Ever wish that `find` were a built-in shell loop?*
-   *Do you want your script to work on nearly any shell on any Unix-like OS?*

Modernish is a library for shell script programming which provides features
like safer variable and command expansion, new language constructs for loop
iteration, and much more. There is no compiled code to install; modernish is
written entirely in the shell language. It can be deployed in embedded or
multiuser systems in which new binary executables may not be introduced for
security reasons, and is portable among numerous shell implementations.
Modernish programs are shell programs; the new constructs are mixed with
shell syntax so that the programmer can take advantage of the best of both.

**After more than three years of initial development, modernish is now in the
alpha test stage.** Join us and help breathe some new life into the shell! We
are looking for testers, early adopters, and developers to join us.
[Download the latest alpha release](https://github.com/modernish/modernish/releases)
or check out the very latest development code from the master branch.
Read through the documentation below. Play with the example scripts and
write your own. Try to break the library and send reports of breakage.
Communicate via the github page, or join the mailing lists:
[modernish-dev](https://lists.inlv.org/sympa/info/modernish-dev),
[modernish-users](https://lists.inlv.org/sympa/info/modernish-users),
[modernish-announce](https://lists.inlv.org/sympa/info/modernish-announce).


## Table of contents ##

* [Getting started](#user-content-getting-started)
* [Two basic forms of a modernish program](#user-content-two-basic-forms-of-a-modernish-program)
    * [Simple form](#user-content-simple-form)
    * [Portable form](#user-content-portable-form)
* [Interactive use](#user-content-interactive-use)
* [Non-interactive command line use](#user-content-non-interactive-command-line-use)
    * [Non-interactive usage examples](#user-content-non-interactive-usage-examples)
* [Shell capability detection](#user-content-shell-capability-detection)
* [Names and identifiers](#user-content-names-and-identifiers)
    * [Internal namespace](#user-content-internal-namespace)
    * [Modernish system constants](#user-content-modernish-system-constants)
    * [Control character, whitespace and shell-safe character constants](#user-content-control-character-whitespace-and-shell-safe-character-constants)
* [Reliable emergency halt](#user-content-reliable-emergency-halt)
* [Low-level shell utilities](#user-content-low-level-shell-utilities)
    * [Outputting strings](#user-content-outputting-strings)
    * [Legibility aliases: `not`, `so`, `forever`](#user-content-legibility-aliases-not-so-forever)
    * [Enhanced `exit`](#user-content-enhanced-exit)
    * [`insubshell`](#user-content-insubshell)
    * [`isset`](#user-content-isset)
    * [`setstatus`](#user-content-setstatus)
* [Testing numbers, strings and files](#user-content-testing-numbers-strings-and-files)
    * [Integer number arithmetic tests and operations](#user-content-integer-number-arithmetic-tests-and-operations)
        * [The arithmetic command `let`](#user-content-the-arithmetic-command-let)
        * [Arithmetic shortcuts](#user-content-arithmetic-shortcuts)
    * [String and file tests](#user-content-string-and-file-tests)
        * [String tests](#user-content-string-tests)
            * [Unary string tests](#user-content-unary-string-tests)
            * [Binary string matching tests](#user-content-binary-string-matching-tests)
            * [Multi-matching option](#user-content-multi-matching-option)
        * [File type tests](#user-content-file-type-tests)
        * [File comparison tests](#user-content-file-comparison-tests)
        * [File status tests](#user-content-file-status-tests)
        * [I/O tests](#user-content-io-tests)
        * [File permission tests](#user-content-file-permission-tests)
* [The stack](#user-content-the-stack)
    * [The shell options stack](#user-content-the-shell-options-stack)
    * [The trap stack](#user-content-the-trap-stack)
* [Modules](#user-content-modules)
    * [`use safe`](#user-content-use-safe)
        * [Why the safe mode?](#user-content-why-the-safe-mode)
        * [How the safe mode works](#user-content-how-the-safe-mode-works)
        * [Important notes for safe mode](#user-content-important-notes-for-safe-mode)
        * [Extra options for the safe mode](#user-content-extra-options-for-the-safe-mode)
    * [`use var/loop`](#user-content-use-varloop)
        * [Enumerative `for`/`select` loop with safe split/glob](#user-content-enumerative-forselect-loop-with-safe-splitglob)
        * [The `find` loop](#user-content-the-find-loop)
            * [`find` loop usage examples](#user-content-find-loop-usage-examples)
        * [Simple repeat loop](#user-content-simple-repeat-loop)
        * [BASIC-style arithmetic `for` loop](#user-content-basic-style-arithmetic-for-loop)
        * [C-style arithmetic `for` loop](#user-content-c-style-arithmetic-for-loop)
        * [Creating your own loop](#user-content-creating-your-own-loop)
    * [`use var/local`](#user-content-use-varlocal)
        * [Important `var/local` usage notes](#user-content-important-varlocal-usage-notes)
    * [`use var/arith`](#user-content-use-vararith)
        * [Arithmetic operator shortcuts](#user-content-arithmetic-operator-shortcuts)
        * [Arithmetic comparison shortcuts](#user-content-arithmetic-comparison-shortcuts)
    * [`use var/assign`](#user-content-use-varassign)
    * [`use var/mapr`](#user-content-use-varmapr)
        * [Differences from `mapfile`](#user-content-differences-from-mapfile)
        * [Differences from `xargs`](#user-content-differences-from-xargs)
    * [`use var/readf`](#user-content-use-varreadf)
    * [`use var/shellquote`](#user-content-use-varshellquote)
        * [`shellquote`](#user-content-shellquote)
        * [`shellquoteparams`](#user-content-shellquoteparams)
    * [`use var/stack`](#user-content-use-varstack)
        * [`use var/stack/extra`](#user-content-use-varstackextra)
        * [`use var/stack/trap`](#user-content-use-varstacktrap)
            * [Trap stack compatibility considerations](#user-content-trap-stack-compatibility-considerations)
            * [The new `DIE` pseudosignal](#user-content-the-new-die-pseudosignal)
    * [`use var/string`](#user-content-use-varstring)
        * [`use var/string/touplow`](#user-content-use-varstringtouplow)
        * [`use var/string/trim`](#user-content-use-varstringtrim)
        * [`use var/string/replacein`](#user-content-use-varstringreplacein)
        * [`use var/string/append`](#user-content-use-varstringappend)
    * [`use var/unexport`](#user-content-use-varunexport)
    * [`use var/genoptparser`](#user-content-use-vargenoptparser)
    * [`use sys/base`](#user-content-use-sysbase)
        * [`use sys/base/mktemp`](#user-content-use-sysbasemktemp)
        * [`use sys/base/readlink`](#user-content-use-sysbasereadlink)
        * [`use sys/base/rev`](#user-content-use-sysbaserev)
        * [`use sys/base/seq`](#user-content-use-sysbaseseq)
            * [Differences with GNU and BSD `seq`](#user-content-differences-with-gnu-and-bsd-seq)
        * [`use sys/base/shuf`](#user-content-use-sysbaseshuf)
        * [`use sys/base/tac`](#user-content-use-sysbasetac)
        * [`use sys/base/which`](#user-content-use-sysbasewhich)
        * [`use sys/base/yes`](#user-content-use-sysbaseyes)
    * [`use sys/cmd`](#user-content-use-syscmd)
        * [`use sys/cmd/extern`](#user-content-use-syscmdextern)
        * [`use sys/cmd/harden`](#user-content-use-syscmdharden)
            * [Important note on variable assignments](#user-content-important-note-on-variable-assignments)
            * [Hardening while allowing for broken pipes](#user-content-hardening-while-allowing-for-broken-pipes)
            * [Tracing the execution of hardened commands](#user-content-tracing-the-execution-of-hardened-commands)
            * [Simple tracing of commands](#user-content-simple-tracing-of-commands)
        * [`use sys/cmd/procsubst`](#user-content-use-syscmdprocsubst)
        * [`use sys/cmd/source`](#user-content-use-syscmdsource)
    * [`use sys/dir`](#user-content-use-sysdir)
        * [`use sys/dir/countfiles`](#user-content-use-sysdircountfiles)
        * [`use sys/dir/mkcd`](#user-content-use-sysdirmkcd)
    * [`use sys/term`](#user-content-use-systerm)
        * [`use sys/term/putr`](#user-content-use-systermputr)
        * [`use sys/term/readkey`](#user-content-use-systermreadkey)
* [Appendix A: List of shell cap IDs](#user-content-appendix-a-list-of-shell-cap-ids)
    * [Capabilities](#user-content-capabilities)
    * [Quirks](#user-content-quirks)
    * [Bugs](#user-content-bugs)
    * [Warning IDs](#user-content-warning-ids)
* [Appendix B: Regression test suite](#user-content-appendix-b-regression-test-suite)
    * [Difference between capability detection and regression tests](#user-content-difference-between-capability-detection-and-regression-tests)
    * [Testing modernish on all your shells](#user-content-testing-modernish-on-all-your-shells)
* [Appendix C: Supported locales](#user-content-appendix-c-supported-locales)
* [Appendix D: Supported shells](#user-content-appendix-d-supported-shells)
* [Appendix E: zsh: integration with native scripts](#user-content-appendix-e-zsh-integration-with-native-scripts)


## Getting started ##

Run `install.sh` and follow instructions, choosing your preferred shell
and install location. After successful installation you can run modernish
shell scripts and write your own. Run `uninstall.sh` to remove modernish.

Both the install and uninstall scripts are interactive by default, but
support fully automated (non-interactive) operation as well. Command
line options are as follows:

`install.sh` [ `-n` ] [ `-s` *shell* ] [ `-f` ] [ `-P` *pathspec* ] [ `-d` *installroot* ] [ `-D` *prefix* ]

* `-n`: non-interactive operation
* `-s`: specify default shell to execute modernish
* `-f`: force unconditional installation on specified shell
* `-P`: specify an alternative [`DEFPATH`](#user-content-modernish-system-constants)
        for the installation (be careful; usually *not* recommended)
* `-d`: specify root directory for installation
* `-D`: extra destination directory prefix (for packagers)

`uninstall.sh` [ `-n` ] [ `-f` ] [ `-d` *installroot* ]

* `-n`: non-interactive operation
* `-f`: delete `*/modernish` directories even if files left
* `-d`: specify root directory of modernish installation to uninstall


## Two basic forms of a modernish program ##

In the *simple form*, modernish is added to a script written for a specific
shell. In the *portable form*, your script is shell-agnostic and may run on any
[shell that can run modernish](#user-content-appendix-d-supported-shells).

### Simple form ###

The **simplest** way to write a modernish program is to source modernish as a
dot script. For example, if you write for bash:

```sh
#! /bin/bash
. modernish
use safe
use sys/base
...your program starts here...
```

The modernish `use` command load modules with optional functionality. The
`safe` module initialises the [safe mode](#user-content-use-safe).
The `sys/base` module contains modernish versions of certain basic but
non-standardised utilities (e.g. `readlink`, `mktemp`, `which`), guaranteeing
that modernish programs all have a known version at their disposal. There are
many other modules as well. See [Modules](#user-content-modules) for more
information.

The above method makes the program dependent on one particular shell (in this
case, bash). So it is okay to mix and match functionality specific to that
particular shell with modernish functionality.

(On **zsh**, there is a way to integrate modernish with native zsh scripts. See
[Appendix E](#user-content-appendix-e-zsh-integration-with-native-scripts).)

### Portable form ###

The **most portable** way to write a modernish program is to use the special
generic hashbang path for modernish programs. For example:

```sh
#! /usr/bin/env modernish
#! use safe
#! use sys/base
...your program begins here...
```

For portability, it is important there is no space after `env modernish`;
NetBSD and OpenBSD consider trailing spaces part of the name, so `env` will
fail to find modernish.

A program in this form is executed by whatever shell the user who installed
modernish on the local system chose as the default shell. Since you as the
programmer can't know what shell this is (other than the fact that it passed
some rigorous POSIX compliance testing executed by modernish), a program in
this form *must be strictly POSIX compliant* – except, of course, that it
should also make full use of the rich functionality offered by modernish.

Note that modules are loaded in a different way: the `use` commands are part of
hashbang comment (starting with `#!` like the initial hashbang path). Only such
lines that *immediately* follow the initial hashbang path are evaluated; even
an empty line in between causes the rest to be ignored.
This special way of pre-loading modules is needed to make any aliases they
define work reliably on all shells.


## Interactive use ##

Modernish is primarily designed to enhance shell programs/scripts, but also
offers features for use in interactive shells. For instance, the new `repeat`
loop construct from the `var/loop` module can be quite practical to repeat
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

1. `modernish` [ `--use=`*module* | *shelloption* ... ]
   [ *scriptfile* ] [ *arguments* ]
2. `modernish` [ `--use=`*module* | *shelloption* ... ]
   `-c` [ *script* [ *me-name* [ *arguments* ] ] ]
3. `modernish --test`
4. `modernish --version`

In the first form, the script in the file *scriptfile* is
loaded and executed with any *arguments* assigned to the positional parameters.

In the second form, `-c` executes the specified modernish
*script*, optionally with the *me-name* assigned to `$ME` and the
*arguments* assigned to the positional parameters.

The `--use` option preloads any given modernish [modules](#user-content-modules)
before executing the script.
The *module* argument to each specified `--use` option is split using
standard shell field splitting. The first field is the module name and any
further fields become arguments to that module's initialisation routine.

Any given short-form or long-form *shelloption*s are
set or unset before executing the script. Both POSIX
[shell options](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_25_03)
and shell-specific options are supported, depending on
[the shell executing modernish](#user-content-appendix-d-supported-shells).
Using the shell option `-e` or `-o errexit` is an error, because modernish
[does not support it](#user-content-use-syscmdharden) and
would break.

The `--test` option runs the regression test suite and exits. This verifies
that the modernish installation is functioning correctly. See
[Appendix B](#user-content-appendix-b-regression-test-suite)
for more information.

The `--version` option outputs the version of modernish and exits.

### Non-interactive usage examples ###

* Count to 10 using a [basic loop](#user-content-use-varloop):    
  `modernish --use=var/loop -c 'LOOP for i=1 to 10; DO putln "$i"; DONE'`
* Run a [portable-form](#user-content-portable-form)
  modernish program using zsh and enhanced-prompt xtrace:    
  `zsh /usr/local/bin/modernish -o xtrace /path/to/program.sh`

## Shell capability detection ##

Modernish includes a battery of shell bug, quirk and feature detection
tests, each of which is given a special ID.
See [Appendix A](#user-content-appendix-a-list-of-shell-cap-ids) below for a
list of shell capabilities, quirks and bugs that modernish currently detects,
as well as further general information on the feature detection framework.

`thisshellhas` is the central function of the modernish feature detection
framework. It not only tests for the presence of modernish shell
capabilities/quirks/bugs on the current shell, but can also test for the
presence of specific shell built-in commands, shell reserved words (a.k.a.
keywords), shell options (short or long form), and signals.

Modernish itself extensively uses feature detection to adapt itself to the
shell it's running on. This is how it works around shell bugs and takes
advantage of efficient features not all shells have. But any script using
the library can do this in the same way, with the help of this function.

Test results are cached in memory, so repeated checks using `thisshellhas`
are efficient and there is no need to avoid calling it to optimise
performance.

Usage:

`thisshellhas` [ `--cache` | `--show` ] *item* [ *item* ... ]

* If *item* contains only ASCII capital letters A-Z, digits 0-9 or `_`,
  return the result status of the associated modernish
  [feature, quirk or bug test](#user-content-appendix-a-list-of-shell-cap-ids).
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
  **Note:** This option requires the
  [`var/stack/trap`](#user-content-use-varstacktrap) module.
* If *item* is `-o` followed by a separate word, check if this shell has a
  long-form shell option by that name.
* If *item* is any other letter or digit preceded by a single `-`, check if
  this shell has a short-form shell option by that character.
* The `--cache` option runs all external modernish shell capability tests
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


## Names and identifiers ##

All modernish functions require portable variable and shell function names,
that is, ones consisting of ASCII uppercase and lowercase letters, digits,
and the underscore character `_`, and that don't begin with digit. For shell
option names, the constraints are the same except a dash `-` is also
accepted. An invalid identifier is generally treated as a fatal error.

### Internal namespace ###

Function-local variables are not supported by the standard POSIX shell; only
global variables are provided for. Modernish needs a way to store its
internal state without interfering with the program using it. So most of the
modernish functionality uses an internal namespace `_Msh_*` for variables,
functions and aliases. All these names may change at any time without
notice. *Any names starting with `_Msh_` should be considered sacrosanct and
untouchable; modernish programs should never directly use them in any way.*
Of course this is not enforceable, but names starting with `_Msh_` should be
uncommon enough that no unintentional conflict is likely to occur.

### Modernish system constants ###

Modernish provides certain constants (read-only variables) to make life easier.
These include:

* `$MSH_VERSION`: The version of modernish.
* `$MSH_PREFIX`: Installation prefix for this modernish installation (e.g.
  /usr/local).
* `$MSH_MDL`: Main [modules](#user-content-modules) directory.
* `$MSH_AUX`: Main helper scripts directory.
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
  `SIGPIPE` and exits with that particular status.
  Hardened commands or functions may need to handle such a `SIGPIPE` exit
  specially to avoid unduly killing the program. The exact value of this
  exit status is shell-specific, so modernish runs a quick test to determine
  it at initialisation time.    
  If `SIGPIPE` was set to ignore by the process that invoked the current
  shell, `$SIGPIPESTATUS` can't be detected and is set to the special value
  99999. See also the description of the
  [`WRN_NOSIGPIPE`](#user-content-warning-ids)
  ID for
  [`thisshellhas`](#user-content-shell-capability-detection).
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

Usage examples:

```sh
# Use a glob pattern to check against control characters in a string:
	if str match "$var" "*[$CONTROLCHARS]*"; then
		putln "\$var contains at least one control character"
	fi
# Use '!' (not '^') to check for characters *not* part of a particular set:
	if str match "$var" "*[!$ASCIICHARS]*"; then
		putln "\$var contains at least one non-ASCII character" ;;
	fi
# Safely split fields at any whitespace, comma or slash (requires safe mode):
	use safe
	LOOP for --split=$WHITESPACE,/ field in $my_items; DO
		putln "Item: $field"
	DONE
```

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
In addition, if `die` is invoked from a subshell such as a background job, it
kills all processes belonging to that job, but leaves other running jobs alone.

Usage: `die` [ *message* ]

If the [trap stack module](#user-content-use-varstacktrap)
is active, a special
[`DIE` pseudosignal](#user-content-the-new-die-pseudosignal)
can be trapped (using plain old `trap` or
[`pushtrap`](#user-content-the-trap-stack))
to perform emergency cleanup commands upon invoking `die`.


## Low-level shell utilities ##

### Outputting strings ###

The POSIX shell lacks a simple, straightforward and portable way to output
arbitrary strings of text, so modernish adds two commands for this.

* `put` prints each argument separated by a space, without a trailing newline.
* `putln` prints each argument, terminating each with a newline character.

There is no processing of options or escape codes. (Modernish constants
[`$CCn`, etc.](#user-content-control-character-whitespace-and-shell-safe-character-constants)
can be used to insert control characters in double-quoted strings. To process escape codes, use
[`printf`](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/printf.html)
instead.)

The `echo` command is notoriously unportable and kind of broken, so is
**deprecated** in favour of `put` and `putln`. Modernish does provide its own
version of `echo`, but it is only activated for
[portable-form](#user-content-portable-form))
scripts. Otherwise, the shell-specific version of `echo` is left intact.
The modernish version of `echo` does not interpret any escape codes
and supports only one option, `-n`, which, like BSD `echo`, suppresses the
final newline. However, unlike BSD `echo`, if `-n` is the only argument, it is
not interpreted as an option and the string `-n` is printed instead. This makes
it safe to output arbitrary data using this version of `echo` as long as it is
given as a single argument (using quoting if needed).

### Legibility aliases: `not`, `so`, `forever` ###

Modernish sets three aliases that can help to make the shell language look
slightly friendlier. Their use is optional.

`not` is a new synonym for `!`. They can be used interchangeably.

`so` is a command that tests if the previous command exited with a status
of zero, so you can test the preceding command's success with `if so` or
`if not so`.

`forever` is a new synonym for `while :;`. This allows simple infinite loops
of the form: `forever do` *stuff*`; done`.

### Enhanced `exit` ###

The `exit` command can be used as normal, but has gained capabilities.

Extended usage: `exit` [ `-u` ] [ *status* [ *message* ] ]

* As per standard, if *status* is not specified, it defaults to the exit
  status of the command executed immediately prior to `exit`.
  Otherwise, it is evaluated as a shell arithmetic expression. If it is
  invalid as such, the shell exits immediately with an arithmetic error.
* Any remaining arguments after *status* are combined, separated by spaces,
  and taken as a *message* to print on exit. The message shown is preceded by
  the name of the current program (`$ME` minus directories). Note that it is
  not possible to skip *status* while specifying a *message*.
* If the `-u` option is given, and the shell function `showusage` is defined,
  that function is run in a subshell before exiting. It is intended to print
  a message showing how the command should be invoked. The `-u` option has no
  effect if the script has not defined a `showusage` function.
* If *status* is non-zero, the *message* and the output of the `showusage`
  function are redirected to standard error.

### `insubshell` ###

The `insubshell` function checks if you're currently running in a
[subshell environment](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_12)
(usually called simply *subshell*), that is, a copy of the parent shell that
starts out as an exact duplicate except for traps. This is not to be confused
with a newly initialised shell that is merely a child process of the current
shell, which is sometimes (erroneously) called a "subshell" as well.

Usage: `insubshell` [ `-p` | `-u` ]

This function returns success (0) if it was called from within a subshell
and non-success (1) if not. One of two options can be given:
* `-p`: Store the process ID (PID) of the current subshell or main shell
  in `REPLY`.
* `-u`: Store an identifier in `REPLY` that is useful for determining if
  you've entered a subshell relative to a previously stored identifier. The
  content and format are unspecified and shell-dependent.

### `isset` ###

`isset` checks if a variable, shell function or option is set, or has
certain attributes. Usage:

* `isset` *varname*: Check if a variable is set.
* `isset -v` *varname*: Id.
* `isset -x` *varname*: Check if variable is exported.
* `isset -r` *varname*: Check if variable is read-only.
* `isset -f` *funcname*: Check if a shell function is set.
* `isset -`*optionletter* (e.g. `isset -C`): Check if shell option is set.
* `isset -o` *optionname*: Check if shell option is set by long name.

Exit status: 0 if the item is set; 1 if not; 2 if the argument is not
recognised as a [valid identifier](#user-content-names-and-identifiers).
Unlike most other modernish commands, `isset` does not treat an invalid
identifier as a fatal error.

When checking a shell option, a nonexistent shell option is not an error,
but returns the same result as an unset shell option. (To check if a shell
option exists, use [`thisshellhas`](#user-content-shell-capability-detection).

Note: just `isset -f` checks if shell option `-f` (a.k.a. `-o noglob`) is
set, but with an extra argument, it checks if a shell function is set.
Similarly, `isset -x` checks if shell option `-x` (a.k.a `-o xtrace`)
is set, but `isset -x` *varname* checks if a variable is exported. If you
use unquoted variable expansions here, make sure they're not empty, or
the shell's empty removal mechanism will cause the wrong thing to be checked
(even in the [safe mode](#user-content-use-safe)).

### `setstatus` ###

`setstatus` manually sets the exit status `$?` to the desired value. The
function exits with the status indicated. This is useful in conditional
constructs if you want to prepare a particular exit status for a subsequent
`exit` or `return` command to inherit under certain circumstances.
The status argument is a parsed as a shell arithmetic expression. A negative
value is treated as a fatal error. The behaviour of values greater than 255
is not standardised and depends on your particular shell.


## Testing numbers, strings and files ##

The `test`/`[` command is the bane of casual shell scripters. Even advanced
shell programmers are frequently caught unaware by one of the many pitfalls
of its arcane, hackish syntax. It attempts to look like shell grammar without
*being* shell grammar, causing myriad problems
([1](http://wiki.bash-hackers.org/commands/classictest),
[2](https://mywiki.wooledge.org/BashPitfalls)).
Its `-a`, `-o`, `(` and `)` operators are *inherently and fatally broken* as
there is no way to reliably distinguish operators from operands, so POSIX
[deprecates their use](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/test.html#tag_20_128_16);
however, most manual pages do not include this essential information, and
even the few that do will not tell you what to do instead.

Ksh, zsh and bash offer a `[[` alternative that fixes many of these problems,
as it is integrated into the shell grammar. Nevertheless, it increases
confusion, as entirely different grammar and quoting rules apply
within `[[`...`]]` than outside it, yet many scripts end up using them
interchangebaly. It is also not available on all POSIX shells. (To make
matters worse, Busybox ash has a false-friend `[[` that is just an alias
of `[`, with none of the shell grammar integration!)

Finally, the POSIX `test`/`[` command is incompatible with the modernish
"safe mode" which aims to eliminate most of the need to quote variables.
See [`use safe`](#user-content-use-safe) for more information.

Modernish deprecates `test`/`[` and `[[` completely. Instead, it offers a
comprehensive alternative command design that works with the usual shell
grammar in a safer way while offering various feature enhancements. The
following replacements are available:

### Integer number arithmetic tests and operations ###

To test if a string is a valid number in shell syntax, `str isint` is
available. See [String tests](#user-content-string-tests).

#### The arithmetic command `let` ####
An implementation of `let` as in ksh, bash and zsh is now available to all
POSIX shells. This makes C-style signed integer arithmetic evaluation
available to every
[supported shell](#user-content-appendix-d-supported-shells),
*with the exception of the unary `++` and `--` operators*
(which are a nonstandard shell capability detected by modernish under the ID of
[`ARITHPP`](#user-content-appendix-a-list-of-shell-cap-ids)).

This means `let` should be used for operations and tests, e.g. both
`let "x=5"` and `if let "x==5"; then`... are supported (note: single `=` for
assignment, double `==` for comparison). See POSIX
[2.6.4 Arithmetic Expansion](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_06_04)
for more information on the supported operators.

Multiple expressions are supported, one per argument. The exit status of `let`
is zero (the shell's idea of success/true) if the last expression argument
evaluates to non-zero (the arithmetic idea of true), and 1 otherwise.

It is recommended to adopt the habit to quote each `let` expression with
`"`double quotes`"`, as this consistently makes everything work as expected:
double quotes protect operators that would otherwise be misinterpreted as
shell grammar, while shell expansions starting with `$` continue to work.

#### Arithmetic shortcuts ####
Various handy functions that make common arithmetic operations
and comparisons easier to program are available from the
[`var/arith`](#user-content-use-vararith) module.

### String and file tests ###

The following notes apply to all commands described in the subsections of
this section:
1. "True" is understood to mean exit status 0, and "false" is understood to
   mean a non-zero exit status – specifically 1.
2. Passing *more* than the number of arguments specified for each command
   is a [fatal error](#user-content-reliable-emergency-halt). (If the
   [safe mode](#user-content-use-safe) is not used, excessive arguments
   may be generated accidentally if you forget to quote a variable. The
   test result would have been wrong anyway, so modernish kills the
   program immediately, which makes the problem much easier to trace.)
3. Passing *fewer* than the number of arguments specified to the command is
   assumed to be the result of removal of an empty unquoted expansion.
   Where possible, this is not treated as an error, and an exit status
   corresponding to the omitted argument(s) beign empty is returned instead.
   (This helps make the [safe mode](#user-content-use-safe) possible; unlike
   with `test`/`[`, paranoid quoting to avoid empty removal is not needed.)

#### String tests ####
The `str` function offers various operators for tests on strings. For
example, `str in $foo "bar"` tests if the variable `foo` contains "bar".

The `str` function takes unary (one-argument) operators that check a property
of a single word, binary (two-argument) operators that check a word against a
pattern, as well as an option that makes binary operators check multiple words
against a pattern.

##### Unary string tests ####
Usage: `str` *operator* [ *word* ]

The *word* is checked for the property indicated by *operator*; if the result
is true, `str` returns status 0, otherwise it returns status 1.

The available unary string test *operator*s are:

* `empty`: The *word* is empty.
* `isint`: The *word* is a decimal, octal or hexadecimal integer number in
  valid POSIX shell syntax, safe to use with `let`, `$((`...`))` and other
  arithmetic contexts on all POSIX-derived shells. This operator ignores
  leading (but not trailing) spaces and tabs.
* `isvarname`: The *word* is a valid portable shell variable or function name.

If *word* is omitted, it is treated as empty, on the assumption that it is
an unquoted empty variable. Passing more than one argument after the
*operator* is a fatal error.

##### Binary string matching tests #####
Usage: `str` *operator* [ [ *word* ] *pattern* ]

The *word* is compared to the *pattern* according to the *operator*; if it
matches, `str` returns status 0, otherwise it returns status 1.
The available binary matching *operator*s are:

* `eq`: *word* is equal to *pattern*.
* `ne`: *word* is not equal to *pattern*.
* `in`: *word* includes *pattern*.
* `begin`: *word* begins with *pattern*.
* `end`: *word* ends with *pattern*.
* `match`: *word* matches *pattern* as a shell glob pattern
  (as in the shell's native `case` construct).
  A *pattern* that ends in an unescaped backslash is considered invalid
  and causes `str` to return status 2.
* `ematch`: *word* matches *pattern* as a POSIX
  [extended regular expression](http://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap09.html#tag_09_04).
  An empty *pattern* is a fatal error.
  (In UTF-8 locales, check if
  <code>thisshellhas [WRN_EREMBYTE](#user-content-warning-ids)</code>
  before matching multibyte characters.)
* `lt`: *word* lexically sorts before (is 'less than') *pattern*.
* `le`: *word* is lexically 'less than or equal to' *pattern*.
* `gt`: *word* lexically sorts after (is 'greater than') *pattern*.
* `ge`: *word* is lexically 'greater than or equal to' *pattern*.

If *word* is omitted, it is treated as empty on the assumption that it is an
unquoted empty variable, and the single remaining argument is assumed to be
the *pattern*. Similarly, if both *word* and *pattern* are omitted, an empty
*word* is matched against an empty *pattern*. Passing more than two
arguments after the *operator* is a fatal error.

##### Multi-matching option #####
Usage: `str -M` *operator* [ [ *word* ... ] *pattern* ]

The `-M` option causes `str` to compare any number of *word*s to the
*pattern*. The available *operator*s are the same as the binary string
matching operators listed above.

All matching *word*s are stored in the `REPLY` variable, separated
by newline characters (`$CCn`) if there is more than one match.
If no *word*s match, `REPLY` is unset.

The exit status returned by `str -M` is as follows:

* If no *word*s match, the exit status is 1.
* If one *word* matches, the exit status is 0.
* If between two and 254 *word*s match, the exit status is the number of matches.
* If 255 or more *word*s match, the exit status is 255.

Usage example: the following matches a given GNU-style long-form command
line option `$1` against a series of available options. To make it possible
for the options to be abbreviated, we check if any of the options begin with
the given argument `$1`.

```sh
if str -M begin --fee --fi --fo --fum --foo --bar --baz --quux "$1"; then
	putln "OK. The given option $1 matched $REPLY"
else
	case $? in
	( 1 )	putln "No such option: $1" >&2 ;;
	( * )	putln "Ambiguous option: $1" "Did you mean:" "$REPLY" >&2 ;;
	esac
fi
```

#### File type tests ####
These avoid the snags with symlinks you get with `[` and `[[`.
By default, symlinks are *not* followed. Add `-L` to operate on files
pointed to by symlinks instead of symlinks themselves (the `-L` makes
no difference if the operands are not symlinks).

These commands all take one argument. If the argument is absent, they return
false. More than one argument is a fatal error. See notes 1-3 in the
[parent section](#user-content-string-and-file-tests).

`is present` *file*: Returns true if the file is present in the file
system (even if it is a broken symlink).

`is -L present` *file*: Returns true if the file is present in the file
system and is not a broken symlink.

`is sym` *file*: Returns true if the file is a symbolic link (symlink).

`is -L sym` *file*: Returns true if the file is a non-broken symlink, i.e.
a symlink that points (either directly or indirectly via other symlinks)
to a non-symlink file that is present in the file system.

`is reg` *file*: Returns true if *file* is a regular data file.

`is -L reg` *file*: Returns true if *file* is either a regular data file
or a symlink pointing (either directly or indirectly via other symlinks)
to a regular data file.

Other commands are available that work exactly like `is reg` and `is -L reg`
but test for other file types. To test for them, replace `reg` with one of:
* `dir` for a directory
* `fifo` for a named pipe (FIFO)
* `socket` for a socket
* `blockspecial` for a block special file
* `charspecial` for a character special file

#### File comparison tests ####
The following notes apply to these commands:
* Symlinks are *not* resolved/followed by default. To operate on files pointed
  to by symlinks, add `-L` before the operator argument, e.g. `is -L newer`.
* Omitting any argument is a fatal error, because no empty argument (removed or
  otherwise) would make sense for these commands.

`is newer` *file1* *file2*: Compares file timestamps, returning true if *file1*
is newer than *file2*. Also returns true if *file1* exists, but *file2* does
not; this is consistent for all shells (unlike `test file1 -nt file2`).

`is older` *file1* *file2*: Compares file timestamps, returning true if *file1*
is older than *file2*. Also returns true if *file1* does not exist, but *file2*
does; this is consistent for all shells (unlike `test file1 -ot file2`).

`is samefile` *file1* *file2*: Returns true if *file1* and *file2* are the same
file (hardlinks).

`is onsamefs` *file1* *file2*: Returns true if *file1* and *file2* are on the
same file system. If any non-regular, non-directory files are specified, their
parent directory is tested instead of the file itself.

#### File status tests ####
These always follow symlinks.

`is nonempty` *file*: Returns true if the *file* exists, is not a broken
symlink, and is not empty. Unlike `[ -s file ]`, this also works
for directories, as long as you have read permission in them.

`is setuid` *file*: Returns true if the *file* has its set-user-ID flag set.

`is setgid` *file*: Returns true if the *file* has its set-group-ID flag set.

#### I/O tests ####
`is onterminal` *FD*: Returns true if file descriptor *FD* is associated
with a terminal. The *FD* may be a non-negative integer number or one of the
special identifiers `stdin`, `stdout` and `stderr` which are equivalent to
0, 1, and 2. For instance, `is onterminal stdout` returns true if commands
that write to standard output (FD 1), such as `putln`, would write to the
terminal, and false if the output is redirected to a file or pipeline.

#### File permission tests ####
Any symlinks given are resolved, as these tests would be meaningless
for a symlink itself.

`can read` *file*: True if the file's permission bits indicate that you can read
the file - i.e., if an `r` bit is set and applies to your user.

`can write` *file*: True if the file's permission bits indicate that you can
write to the file: for non-directories, if a `w` bit is set and applies to your
user; for directories, both `w` and `x`.

`can exec` *file*: True if the file's type and permission bits indicate that
you can execute the file: for regular files, if an `x` bit is set and applies
to your user; for other file types, never.

`can traverse` *file*: True if the file is a directory and its permission bits
indicate that a path can traverse through it to reach its subdirectories: for
directories, if an `x` bit is set and applies to your user; for other file
types, never.


## The stack ##

In modernish, every variable and shell option gets its own stack. Arbitrary
values/states can be pushed onto the stack and popped off it in reverse
order. For variables, both the value and the set/unset state is (re)stored.

Usage:

* `push` [ `--key=`*value* ] *item* [ *item* ... ]
* `pop` [ `--keepstatus` ] [ `--key=`*value* ] *item* [ *item* ... ]

where *item* is a valid portable variable name, a short-form shell option
(dash plus letter), or a long-form shell option (`-o` followed by an option
name, as two arguments).

Before pushing or popping anything, both functions check if all the given
arguments are valid and `pop` checks all items have a non-empty stack. This
allows pushing and popping groups of items with a check for the integrity of
the entire group. `pop` exits with status 0 if all items were popped
successfully, and with status 1 if one or more of the given items could not
be popped (and no action was taken at all).

The `--key=` option is an advanced feature that can help different modules
or functions to use the same variable stack safely. If a key is given to
`push`, then for each *item*, the given key *value* is stored along with the
variable's value for that position in the stack. Subsequently, restoring
that value with `pop` will only succeed if the key option with the same key
value is given to the `pop` invocation. Similarly, popping a keyless value
only succeeds if no key is given to `pop`. If there is any key mismatch, no
changes are made and `pop` returns status 2.  Note that this is
a robustness/convenience feature, not a security feature; the keys are not
hidden in any way.

If the `--keepstatus` option is given, `pop` will exit with the
exit status of the command executed immediately prior to calling `pop`. This
can avoid the need for awkward workarounds when restoring variables or shell
options at the end of a function. However, note that this makes failure to pop
(stack empty or key mismatch) a fatal error that kills the program, as `pop`
no longer has a way to communicate this through its exit status.

### The shell options stack ###

`push` and `pop` allow saving and restoring the state of any shell option
available to the `set` builtin. The precise shell options supported
(other than the ones guaranteed by POSIX) depend on
[the shell modernish is running on](#user-content-appendix-d-supported-shells).
To facilitate portability, nonexistent shell options are treated as unset.

Long-form shell options are matched to their equivalent short-form shell
options, if they exist. For instance, on all POSIX shells, `-f` is
equivalent to `-o noglob`, and `push -o noglob` followed by `pop -f` works
correctly. This also works for shell-specific short & long option
equivalents.

On shells with a dynamic `no` option name prefix, that is on ksh, zsh and
yash (where, for example, `noglob` is the opposite of `glob`), the `no`
prefix is ignored, so something like `push -o glob` followed by `pop -o
noglob` does the right thing. But this depends on the shell and should never
be used in portable scripts.

### The trap stack ###

Modernish can also make traps stack-based, so that each
program component or library module can set its own trap commands
without interfering with others. This functionality is provided
by the [`var/stack/trap`](#user-content-use-varstacktrap) module.


## Modules ##

As modularity is one of modernish's
[design principles](https://github.com/modernish/modernish/blob/master/share/doc/modernish/DESIGN.md),
much of its essential functionality is provided in the form of loadable
modules, so the core library is kept lean. Modules are organised
hierarchically, with names such as `safe`, `var/mapr` and `sys/cmd/harden`. The
`use` command loads and initialises a module or a combined directory of modules.

Internally, modules exist in files with the name extension `.mm` in
subdirectories of `lib/modernish/mdl` – for example, the module
`var/stack/trap` corresponds to the file `lib/modernish/mdl/var/stack/trap.mm`.

Usage:
# `use` *modulename* [ *argument* ... ]
# `use` [ `-q` | `-e` ] *modulename*
# `use -l`

The first form loads and initialises a module. All arguments, including the
module name, are passed on to the dot script unmodified, so modules know
their own name and can implement option parsing to influence their
initialisation. See also
[Two basic forms of a modernish program](#user-content-two-basic-forms-of-a-modernish-program)
for information on how to use modules in portable-form scripts.

In the second form, the `-q` option queries if a module is loaded, and the `-e`
option queries if a module exists. `use` returns status 0 for yes and 1 for no.

The `-l` option lists all currently loaded modules in the order in which
they were originally loaded. Just add `| sort` for alphabetical order.

If a directory of modules, such as `sys/cmd` or even just `sys`, is given as the
*modulename*, then all the modules in that directory and any subdirectories are
loaded recursively. In this case, passing extra arguments is a fatal error.

If a module file `X.mm` exists along with a directory `X`, resolving to the
same *modulename*, then `use` will load the `X.mm` module file without
automatically loading any modules in the `X` directory, because it is expected
that `X.mm` handles the submodules in `X` manually. (This is currently the case
for `var/loop` which auto-loads submodules containing loop types on first use).

The complete `lib/modernish/mdl` directory path, which depends on where
modernish is installed, is stored in the system constant `$MSH_MDL`.

The following subchapters document the modules that come with modernish.

### `use safe` ###

The `safe` module sets the 'safe mode' for the shell. It removes most of the
need to quote variables, parameter expansions, command substitutions, or glob
patterns. It uses shell settings and modernish library functionality to secure
and demystify split and glob mechanisms. This creates a new and safer way of
shell script programming, essentially building a new shell language dialect
while still running on all POSIX-compliant shells.

#### Why the safe mode? ####
One of the most common headaches with shell scripting is caused by a
fundamental flaw in the shell as a scripting language: *constantly
active field splitting* (a.k.a. word splitting) *and pathname expansion*
(a.k.a. globbing). To cope with this situation, it is hammered into
programmers of shell scripts to be absolutely paranoid about properly
[quoting](https://mywiki.wooledge.org/Quotes) nearly everything, including
variable and parameter expansions, command substitutions, and patterns passed
to commands like `find`.

These mechanisms were designed for interactive command line usage, where they
do come in very handy. But when the shell language is used as a programming
language, splitting and globbing often ends up being applied unexpectedly to
unquoted expansions and command substitutions, helping cause thousands of
buggy, brittle, or outright dangerous shell scripts.

One could blame the programmer for forgetting to quote an expansion properly,
*or* one could blame a pitfall-ridden scripting language design where hammering
punctilious and counterintuitive habits into casual shell script programmers is
necessary. Modernish does the latter, then fixes it.

#### How the safe mode works ####
Every POSIX shell comes with a little-used ability to disable global field
splitting and pathname expansion: `IFS=''; set -f`. An empty `IFS` variable
disables split; the `-f` (or `-o noglob`) shell option disables pathname
expansion. The safe mode sets these, and two others (see below).

The reason these safer settings are hardly ever used is that they are not
practical to use with the standard shell language. For instance, `for
textfile in *.txt`, or `for item in $(some command)` which both (!)
field-splits *and* pathname-expands the output of a command, all break.

However, that is where modernish comes in. It introduces several powerful
new [loop constructs](#user-content-use-varloop), as well as arbitrary code
blocks with [local settings](#user-content-use-varlocal), each of which
has straightforward, intuitive operators for safely applying field splitting
*or* pathname expansion – to specific command arguments only. By default,
they are *not both* applied to the arguments, which is much safer. And your
script code as a whole is kept safe from them at all times.

With global field splitting and pathname expansion removed, a third issue
still affects the safe mode: the shell's *empty removal* mechanism. If the
value of an unquoted expansion like `$var` is empty, it will not expand to
an empty argument, but will be removed altogether, as if it were never
there. This behaviour cannot be disabled.

Thankfully, the vast majority of shell and Un*x commands order their arguments
in a way that is actually designed with empty removal in mind, making it a
good thing. For instance, when doing `ls $option some_dir`, if `$option` is
`-l` the listing will be long-format and if is empty it will be removed, which
is the desired behaviour. (An empty argument there would cause an error.)

However, one command that is used in almost all shell scripts, `test`/`[`,
is *completely unable to cope with empty removal* due to its idiosyncratic
and counterintuitive syntax. Potentially empty operands come before options,
so operands removed as empty expansions cause errors or, worse, false
positives. Thus, the safe mode does *not* remove the need for paranoid
quoting of expansions used with `test`/`[` commands. Modernish fixes
this issue by *deprecating `test`/`[` completely* and offering
[a safe command design](#user-content-testing-numbers-strings-and-files)
to use instead, which correctly deals with empty removal.

With the 'safe mode' shell settings, plus the safe, explicit and readable
split and glob operators and `test`/`[` replacements, the only quoting
requirements left are:
1. a very occasional need to stop empty removal from happening;
2. to quote `"$@"` and `"$*"` until shell bugs are fixed (see notes below).

In addition to the above, the safe mode also sets these shell options:
* `set -C` (`set -o noclobber`) to prevent accidentally overwriting files using
  output redirection. To force overwrite, use `>|` instead of `>`.
* `set -u` (`set -o nounset`) to make it an error to use unset (that is,
  uninitialised) variables by default. You'll notice this will catch many
  typos before they cause you hard-to-trace problems. To bypass the check
  for a specific variable, use `${var-}` instead of `$var` (be careful).

#### Important notes for safe mode ####
* The safe mode is *not* compatible with existing conventional shell scripts,
  written in what we could now call the 'legacy mode'. Essentially, the safe
  mode is a new way of shell script programming. That is why it is not enabled
  by default, but activated by loading the `safe` module. *It is highly
  recommended that new modernish scripts start out with `use safe`.*
* The shell applies entirely different quoting rules to string matching glob
  patterns within `case` constructs. The safe mode changes nothing here.
* Due to [shell bugs](#user-content-bugs) ID'ed as `BUG_PP_*`, the positional
  parameters expansions `$@` and `$*` should still *always* be quoted. As of
  late 2018, these bugs have been fixed in the latest or upcoming release
  versions of all
  [supported shells](#user-content-appendix-d-supported-shells).
  But, until buggy versions fall out of use
  and modernish no longer supports any `BUG_PP_*` shell bugs, quoting `"$@"`
  and `"$*"` remains mandatory even in safe mode (unless you know with
  certainty that your script will be used on a shell with none of these bugs).
* The behaviour of `"$*"` changes in safe mode. It uses the first character
  of `$IFS` as the separator for combining all positional parameters into
  one string. Since `IFS` is emptied in safe mode, there is no separator,
  so it will string them together unseparated. You can use something like
  [`push IFS; IFS=' '; var="$*"; pop IFS`](#user-content-the-stack)
  or [`LOCAL IFS=' '; BEGIN var="$*"; END`](#user-content-use-varlocal)
  to use the space character as a separator.
  (If you're outputting the positional parameters, note that the
  [`put`](#user-content-outputting-strings)
  command always separates its arguments by spaces, so you can
  safely pass it multiple arguments with `"$@"` instead.)

#### Extra options for the safe mode ####
Usage: `use safe` [ `-k` | `-K` ] [ `-i` ]

The `-k` and `-K` module options install an extra handler that
[reliably kills the program](#user-content-reliable-emergency-halt)
if it tries to execute a command that is not found, on shells that have the
ability to catch and handle 'command not found' errors (currently bash, yash,
and zsh). This helps catch typos, forgetting to load a module, etc., and stops
your program from continuing in an inconsistent state and potentially causing
damage. The `MSH_NOT_FOUND_OK` variable may be set to temporarily disable this
check. The uppercase `-K` module option aborts the program on shells that
cannot handle 'command not found' errors (so should not be used for portable
scripts), whereas the lowercase `-k` variant is ignored on such shells.

The `-i` module option installs two extra functions, `fsplit` and `glob`,
designed to manipulate, examine, save, restore, and generally experiment with
the field splitting and pathname expansion state on interactive shells. On
interactive shells, this option is active by default. See the `safe.mm` file
for more information. In general, the safe mode is designed for scripts and is
not recommended for interactive shells.

### `use var/loop` ###

The `var/loop` module provides an innovative, robust and extensible
shell loop construct. Several powerful loop types are provided, while
advanced shell programmers may find it easy and fun to
[create their own](#user-content-creating-your-own-loop).
This construct is also ideal for the
[safe mode](#user-content-use-safe):
the `for`, `select` and `find` loop types allow you to selectively
apply field splitting and/or pathname expansion to specific arguments
without subjecting a single line of your code to them.

The basic form is a bit different from native shell loops. Note the caps:    
`LOOP` *looptype* *arguments*; `DO`    
&nbsp; &nbsp; &nbsp; *your commands here*    
`DONE`

The familiar `do`...`done` block syntax cannot be used because the shell
will not allow modernish to add its own functionality to it. The
`DO`...`DONE` block does behave in the same way as `do`...`done`: you can
append redirections at the end, pipe commands into a loop, etc. as usual.
The `break` and `continue` shell builtin commands also work as normal.

**Remember:** *using lowercase `do`...`done` with modernish `LOOP` will
cause the shell to throw a misleading syntax error.* So will using uppercase
`DO`...`DONE` with the shell's native loops. To help you remember to use the
uppercase variants for modernish loops, the `LOOP` keyword itself is also in
capitals.

Loops exist in submodules of `var/loop` named after the loop type; for
instance, the `find` loop lives in the `var/loop/find` module. However, the
core `var/loop` module will automatically load a loop type's module when
that loop is first used, so `use`-ing individual loop submodules at your
script's startup time is optional.

The `LOOP` block internally uses file descriptor 8 to do
[its thing](#user-content-creating-your-own-loop).
If your script happens to use FD 8 for other purposes, you should
know that FD 8 is made local to each loop block, and always appears
initially closed within `DO`...`DONE`.

#### Enumerative `for`/`select` loop with safe split/glob ####
The enumarative `for` and `select` loop types mirror those already present in
native shell implementations. However, the modernish versions provide safe
field splitting and globbing (pathname expansion) functionality that can be
used without globally enabling split or glob for any of your code – ideal
for the [safe](#user-content-use-safe) mode. The `select` loop type brings
`select` functionality to all POSIX shells and not just ksh, zsh and bash.

Usage:

`LOOP` [ `for` | `select` ] [ *operators* ] *varname* `in` *argument* ... `;`
`DO` *commands* `;` `DONE`

Simple usage example:

```sh
LOOP select --glob textfile in *.txt; DO
	putln "You chose text file $textfile."
DONE
```

If the loop type is `for`, the loop iterates once for each *argument*, storing
it in the variable named *varname*.

If the loop type is `select`, the loop presents before each iteration a
numbered menu that allows the user to select one of the *argument*s. The prompt
from the `PS3` variable is displayed and a reply read from standard input. The
literal reply is stored in the `REPLY` variable. If the reply was a number
corresponding to an *argument* in the menu, that *argument* is stored in the
variable named *varname*. Then the loop iterates. If the user enters ^D (end of
file), `REPLY` is cleared and the loop breaks with an exit status of 1. (To
break the menu loop under other conditions, use the `break` command.)

The *operators* are only for use in the [safe mode](#user-content-use-safe).
Other use, i.e. with field splitting and/or pathname expansion globally
active, will terminate the program as this would cause an inconsistent
state. The operators are:
* One of `--glob` or `--fglob`. These operators safely apply shell pathname
  expansion (globbing) to the *argument*s given. Each *argument* is taken as
  a pattern, whether or not it contains any wildcard characters. If any
  resulting pathnames start with `-` or are identical to `!` or `(`, they
  automatically get `./` prepended to keep various commands from misparsing
  them as options or operands. Non-matching patterns are treated as follows:
    * `--glob`: Any non-matching patterns are quietly removed. If none match,
      the loop will not iterate but break with exit status 103.
    * `--fglob`: All patterns must match. Any nonexistent path terminates the
      program. Use this if your program would not work after a non-match.
* One of `--split` or `--split=`*characters*. This operator safely applies
  the shell's field splitting mechanism to the *argument*s given. The simple
  `--split` operator applies the shell's default field splitting by space,
  tab, and newline. If you supply one or more of your own *characters* to
  split by, each of these characters will be taken as a field separator if
  it is whitespace, or field terminator if it is non-whitespace. (Note that
  shells with [`QRK_IFSFINAL`](#user-content-quirks) treat both whitespace and
  non-whitespace characters as separators.)

#### The `find` loop ####
This powerful loop type turns your local POSIX-compliant
[`find` utility](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/find.html)
into a shell loop, safely integrating both `find`
and `xargs` functionality into the POSIX shell. The infamous
[pitfalls and limitations](https://dwheeler.com/essays/filenames-in-shell.html#find)
of using `find` and `xargs` as external commands are gone, as all
the results from `find` are readily available to your main shell
script. Any "dangerous" characters in file names (including
whitespace and even newlines) "just work", especially if the
[safe mode](#user-content-use-safe)
is also active. This gives you the flexibility to use either the `find`
expression syntax, or shell commands (including your own shell functions), or
some combination of both, to decide whether and how to handle each file found.

Usage:

`LOOP find` [ *options* ] *varname* [ `in` *path* ... ]
[ *find-expression* ] `;` `DO` *commands* `;` `DONE`

`LOOP find` [ *options* ] `--xargs`[`=`*arrayname*] [ `in` *path* ... ]
[ *find-expression* ] `;` `DO` *commands* `;` `DONE`

`LOOP find` recursively walks down the directory tree for each *path* given.
For each file encountered, it evaluates *find-expression*, which is a standard
[`find`](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/find.html)
expression except as described below. Each time the *find-expression*
evaluates as true, your *commands* are executed with the corresponding
pathname stored in the variable referenced by *varname*.

The modernish `-iterate` expression primary evaluates as true and causes the
loop to iterate, executing your *commands* for each matching file. It may be
used any number of times in the *find-expression* to start a corresponding
series of loop iterations. If it is not given, the loop acts as if the entire
*find-expression* is enclosed in parentheses with `-iterate` appended. If the
entire *find-expression* is omitted, it defaults to `-iterate`.

The entire `in` clause may be omitted, in which case it defaults to `in .`
so the current working directory will be searched. Any argument that starts
with a `-`, or is identical to `!` or `(`, indicates the end of the *path*s
and the beginning of the *find-expression*; if you need to explicitly
specify a path with such a name, prepend `./` to it.

Expression primaries that write output (`-print` and friends) may be used
for debugging the loop. Their output is redirected to standard error.

The familiar non-standard `find` primaries from GNU and BSD, `-or`, `-and`,
`-not`, `-true` and `-false`, may be used portably with `LOOP find`. Before
invoking the `find` utility, modernish translates them internally to
portable equivalents.

The use of the `-ok` and `-okdir` user confirmation primaries is treated as a
fatal error, because this loop invokes the `find` utility as a background
process that is unable to read input from the terminal. Instead, you can ask
the user for confirmation using the shell's `read` command in the loop body.
However, this is not capable of physically influencing the directory traversal.
Simply skipping unwanted files (using `continue` in the loop body) is often a
close-enough alternative. If that is not acceptable, then `-ok` or `-okdir`
should be used with a traditional non-loop `find` utility invocation instead.

All other operands supported by your local `find` utility can be used with
`LOOP find`. However, portable scripts should use only
[operands specified by POSIX](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/find.html#tag_20_47_05)
along with the modernish additions described above.

The *options* are:

* Any single-letter options supported by your local `find` utility. Note that
  [POSIX specifies](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/find.html)
  `-H` and `-L` only, so portable scripts should only use these.
  Options that require arguments (`-f` on BSD `find`) are not supported.
* One of `--glob` or `--fglob`. These operators are only accepted in the
  [safe mode](#user-content-use-safe). They safely apply shell pathname
  expansion (globbing) to the *path* name(s) given *(but **not** to any
  patterns in the *find-expression*, which are passed on to the `find` utility
  as given)*. All *path* names are taken as patterns, whether or not they
  contain any wildcard characters. If any pathnames resulting from the
  expansion start with `-` or are identical to `!` or `(`, they automatically
  get `./` prepended to keep `find` from misparsing them as expression
  operands. Non-matching patterns are treated as follows:
    * `--glob`: Any pattern not matching an existing path will output a
      warning to standard error and set the loop's exit status to 103 upon
      normal completion, even if other existing paths are processed
      successfully. If none match, the loop will not iterate.
    * `--fglob`: All patterns must match. Any nonexistent path terminates
      the program. Use this if your program would not work if there are
      no paths to search in.
* One of `--split` or `--split=`*characters*. This operator, which is only
  accepted in the [safe mode](#user-content-use-safe), safely applies the
  shell's field splitting mechanism to the *path* name(s) given *(but **not**
  to any patterns in the *find-expression*, which are passed on to the `find`
  utility as given)*. The simple `--split` operator applies the shell's default
  field splitting by space, tab, and newline. If you supply one or more of your
  own *characters* to split by, each of these characters will be taken as a
  field separator if it is whitespace, or field terminator if it is
  non-whitespace. (Note that shells with [`QRK_IFSFINAL`](#user-content-quirks)
  treat both whitespace and non-whitespace characters as separators.) If any
  pathname resulting from the split starts with `-` or is identical to `!` or
  `(`, this is a fatal error unless `--glob` or `--fglob` is also given.
* `--xargs`. This operator is specified **instead** of the *varname*; it is a
  syntax error to have both. Instead of one iteration per found item, as many
  items as possible per iteration are stored into the positional parameters
  (PPs), so your program can access them in the usual way (using `"$@"` and
  friends). Note that `--xargs` therefore overwrites the current PPs (however,
  a shell function or [`LOCAL`](#user-content-use-varlocal) block will give
  you local PPs). Modernish clears the PPs upon completion of the loop, but if
  the loop is exited prematurely (such as by `break`), the last chunk survives.
    * On shells with the `KSHARRAY`
      [capability](#user-content-appendix-a-list-of-shell-cap-ids), an
      extra variant is available: `--xargs=`*arrayname* which uses the named
      array instead of the PPs. It otherwise works identically.

Modernish invokes the `find` utility to validate the *options* and the
*find-expression* before beginning to iterate through the loop. Any syntax
error will [terminate the program](#user-content-reliable-emergency-halt).
Unless `--glob` is given, so will a nonexistent *path*.

Other errors or warnings encountered by `find` are considered non-fatal
and will cause the exit status of the loop to be non-zero, so your
script has the opportunity to handle the exception.

##### `find` loop usage examples #####
Simple example script: without the safe mode, the `*.txt` pattern
must be quoted to prevent it from being expanded by the shell.

```sh
. modernish
use var/loop
LOOP find TextFile in ~/Documents -name '*.txt'
DO
	putln "Found my text file: $TextFile"
DONE
```

Example script with [safe mode](#user-content-use-safe): the `--glob` option
expands the patterns of the `in` clause, but *not* the expression – so it
is not necessary to quote any pattern.

```sh
. modernish
use safe
use var/loop
LOOP find --glob lsProg in /*bin /*/*bin -type f -name ls*
DO
	putln "This command may list something: $lsProg"
DONE
```

#### Simple repeat loop ####
This simply iterates the loop the number of times indicated. Before the first
iteration, the argument is evaluated as a shell integer arithmetic expression
as in [`let`](#user-content-integer-number-arithmetic-tests-and-operations)
and its value used as the number of iterations.

```sh
LOOP repeat 3; DO
	putln "This line is repeated 3 times."
DONE
```

#### BASIC-style arithmetic `for` loop ####
This is a slightly enhanced version of the
[`FOR` loop in BASIC](https://en.wikipedia.org/wiki/BASIC#Origin).
It is more versatile than the `repeat` loop but still very easy to use.

`LOOP for` *varname*`=`*initial* to *limit* [ `step` *increment* ]; DO    
&nbsp; &nbsp; &nbsp; *some commands*    
`DONE`

To count from 1 to 20 in steps of 2:

```sh
LOOP for i=1 to 20 step 2; DO
	putln "$i"
DONE
```

Note the *varname*`=`*initial* needs to be one argument as in a shell
assignment (so no spaces around the `=`).

If "`step` *increment*" is omitted, *increment* defaults to 1 if *limit* is
equal to or greater than *initial*, or to -1 if *limit* is less than
*initial* (so counting backwards 'just works').

Technically precise description: On entry, the *initial*, *limit* and
*increment* values are evaluated once as shell arithmetic expressions as in
[`let`](#user-content-integer-number-arithmetic-tests-and-operations),
the value of *initial* is assigned to *varname*, and the loop iterates.
Before every subsequent iteration, the value of *increment* (as determined
on the first iteration) is added to the value of *varname*, then the *limit*
expression is re-evaluated; as long as the current value of *varname* is
less (if *increment* is non-negative) or greater (if *increment* is
negative) than or equal to the current value of *limit*, the loop reiterates.

#### C-style arithmetic `for` loop ####
A C-style for loop akin to `for (( ))` in ksh93, bash and zsh is now
available on all POSIX-compliant shells, with a slightly different syntax.
The one loop argument contains three arithmetic expressions (as in
[`let`](#user-content-integer-number-arithmetic-tests-and-operations)),
separated by semicolons within that argument. The first is only evaluated
before the first iteration, so is typically used to assign an initial value.
The second is evaluated before each iteration to check whether to continue
the loop, so it typically contains some comparison operator. The third is
evaluated before the second and further iterations, and typically increases
or decreases a value. For example, to count from 1 to 10:

```sh
LOOP for "i=1; i<=10; i+=1"; DO
	putln "$i"
DONE
```

However, using complex expressions allows doing much more powerful things.
Any or all of the three expressions may also be left empty (with their
separating `;` character remaining). If the second expression is empty, it
defaults to 1, creating an infinite loop.

(Note that `++i` and `i++` can only be used on shells with
[`ARITHPP`](#user-content-appendix-a-list-of-shell-cap-ids),
but `i+=1` or `i=i+1` can be used on all POSIX-compliant shells.)

#### Creating your own loop ####
The modernish loop construct is extensible. To define a new loop type, you
only need to define a shell function called `_loopgen_`*type* where *type*
is the loop type. This function, called the *loop iteration generator*, is
expected to output lines of text to file descriptor 8, containing properly
[shell-quoted](#user-content-use-varshellquote)
iteration commands for the shell to run, one line per iteration.

The internal commands expanded from `LOOP`, `DO` and `DONE` (which are
defined as aliases) launch that loop iteration generator function in the
background with [safe](#user-content-use-safe) mode enabled, while causing
the main shell to read lines from that background process through a pipe,
`eval`ing each line as a command before iterating the loop. As long as that
iteration command finishes with an exit status of zero, the loop keeps
iterating. If it has a nonzero exit status or if there are no more commands
to read, iteration terminates and execution continues beyond the loop.

Instead of the normal [internal namespace](#user-content-internal-namespace)
which is considered off-limits for modernish scripts, `var/loop` and its
submodules use a `_loop_*` internal namespace for variables, which is also
for use by user-implemented loop iteration generator functions.

The above is just the general principle. For the details, study the comments
and the code in `lib/modernish/mdl/var/loop.mm` and the loop generators in
`lib/modernish/mdl/var/loop/*.mm`.

### `use var/local` ###

This module defines a new `LOCAL`...`BEGIN`...`END` shell code block
construct with local variables, local positional parameters and local shell
options. The local positional parameters can be filled using safe field
splitting and pathname expansion operators similar to those in the `LOOP`
construct described [above](#user-content-use-varloop).

Usage: `LOCAL` [ *localitem* | *operator* ... ] [ `--` [ *word* ... ] ] `;`
`BEGIN` *commands* `;` `END`

The *commands* are executed once, with the specified *localitem*s applied.
Each *localitem* can be:
* A variable name with or without a `=` immediately followed by a value.
  This renders that variable local to the block, initially either unsetting
  it or assigning the value, which may be empty.
* A shell option letter immediately preceded by a `-` or `+` sign. This
  locally turns that shell option on or off, respectively. This follows the
  counterintuitive syntax of `set`. Long-form shell options like `-o`
  *optionname* and `+o` *optionname* are also supported. It depends on the
  shell what options are supported. Specifying a nonexistent option is a
  fatal error. Use [`thisshellhas`](#user-content-shell-capability-detection) to check
  for a non-POSIX option's existence on the current shell before using it.

Modernish implements `LOCAL` blocks as one-time shell functions that use
[the stack](#user-content-the-stack)
to save and restore variables and settings. So the `return` command exits the
block, causing the global variables and settings to be restored and resuming
execution at the point immediately following `END`. Like any shell function, a
`LOCAL` block exits with the exit status of the last command executed within
it, or with the status passed on by or given as an argument to `return`.

The positional parameters (`$@`, `$1`, etc.) are always local to the block, but
a copy is inherited from outside the block by default. Any changes to the
positional parameters made within the block will be discarded upon exiting it.

However, if a double-dash `--` argument is given in the `LOCAL` command line,
the positional parameters outside the block are ignored and the set of *word*s
after `--` (which may be empty) becomes the positional parameters instead.

These *word*s can be modified prior to entering the `LOCAL` block using safe
field splitting and pathname expansion *operator*s. They are only for use in
the [safe mode](#user-content-use-safe). Other use, i.e. with field
splitting and/or pathname expansion globally active, will terminate the
program as this would cause an inconsistent state. The operators are:

* One of `--glob` or `--fglob`. These operators safely apply shell pathname
  expansion (globbing) to the *word*s given. Each *word* is taken as a pattern,
  whether or not it contains any wildcard characters. If any resulting
  pathnames start with `-` or are identical to `!` or `(`, they automatically
  get `./` prepended to keep various commands from misparsing them as options
  or operands. Non-matching patterns are treated as follows:
    * `--glob`: Any non-matching patterns are quietly removed.
    * `--fglob`: All patterns must match. Any nonexistent path terminates the
      program. Use this if your program would not work after a non-match.
* One of `--split` or `--split=`*characters*. This operator safely applies
  the shell's field splitting mechanism to the *word*s given. The simple
  `--split` operator applies the shell's default field splitting by space,
  tab, and newline. If you supply one or more of your own *characters* to
  split by, each of these characters will be taken as a field separator if
  it is whitespace, or field terminator if it is non-whitespace. (Note that
  shells with [`QRK_IFSFINAL`](#user-content-quirks) treat both whitespace and
  non-whitespace characters as separators.)

#### Important `var/local` usage notes ####
* Due to the limitations of aliases and shell reserved words, `LOCAL` has
  to use its own `BEGIN`...`END` block instead of the shell's `do`...`done`.
  Using the latter results in a misleading shell syntax error.
* `LOCAL` blocks do **not** mix well with use of the shell capability
  [`LOCALVARS`](#user-content-user-content-capabilities)
  (shell-native functionality for local variables), especially not on shells
  with `QRK_LOCALUNS` or `QRK_LOCALUNS2`. Using both with the same variables
  causes unpredictable behaviour, depending on the shell.
* **Warning!** Never use `break` or `continue` within a `LOCAL` block to
  resume or break from enclosing loops outside the block! Shells with
  [`QRK_BCDANGER`](#user-content-quirks) allow this, preventing `END` from
  restoring the global settings and corrupting the stack; shells without
  this quirk will throw an error if you try this. A proper way to do what
  you want is to exit the block with a nonzero status using something like
  `return 1`, then append something like `|| break` or `|| continue` to
  `END`. Note that this caveat only applies when crossing `BEGIN`...`END`
  boundaries. Using `continue` and `break` to continue or break loops
  entirely *within* the block is fine.

### `use var/arith` ###

These shortcut functions are alternatives for using
[`let`](#user-content-the-arithmetic-command-let).

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

### `use var/assign` ###

This module is provided to solve a common POSIX shell language annoyance: in a
normal shell variable assignment, only literal variable names are accepted, so
it is impossible to use a variable whose name is stored in another variable.
The only way around this is to use `eval` which is too difficult to use safely.
Instead, you can now use the `assign` command.

Usage: `assign` [ [ `+r` ] *variable*`=`*value* ... ] | [ `-r` *variable*`=`*variable2* ... ] ...

`assign` safely processes assignment-arguments in the same form as customarily
given to the `readonly` and `export` commands, but it only assigns *value*s to
*variable*s without setting any attributes. Each argument is grammatically an
ordinary shell word, so any part or all of it may result from an expansion. The
absence of a `=` character in any argument is a fatal error. The text preceding
the first `=` is taken as the variable name in which to store the *value*; an
invalid *variable* name is a fatal error. No whitespace is accepted before the
`=` and any whitespace after the `=` is part of the *value* to be assigned.

The `-r` (reference) option causes the part to the right of the `=` to be
taken as a second variable name *variable2*, and its value is assigned to
*variable* instead. `+r` turns this option back off.

**Examples:** Each of the lines below assigns the value 'hello world' to the
variable `greeting`.

```sh
var=greeting; assign $var='hello world'
var=greeting; assign "$var=hello world"
tag='greeting=hello world'; assign "$tag"
var=greeting; gvar=myinput; myinput='hello world'; assign -r $var=$gvar
```

### `use var/mapr` ###

`mapr` (map records) is an alternative to `xargs` that shares features with the
`mapfile` command in bash 4.x. It is fully integrated into your script's main
shell environment, so it can call your shell functions as well as builtin and
external utilities. It depends on, and auto-loads, the `sys/cmd/extern` module.

Usage: `mapr` [ `-d` *delimiter* | `-D` ] [ `-n` *count* ] [ -s *count* ]
[ -c *quantum* ] *callback*

`mapr` reads delimited records from the standard input, invoking the specified
*callback* command once or repeatedly as needed, with batches of input records
as arguments. The *callback* may consist of multiple arguments. By default, an
input record is one line of text.

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
* `-m` *length*: Set the maximum argument length in bytes of each *callback*
  command call, including the *callback* command argument(s) and the current
  batch of up to *quantum* input records. The length of each argument is
  increased by 1 to account for the terminating null byte. The default
  maximum length depends on constraints set by the operating system for
  invoking external commands. If *length* is 0, this limit is disabled.
* `-c` *quantum*: Pass at most *quantum* arguments at a time to each call to
  *callback*. If `-c` is not supplied or if *quantum* is 0, the number of
  arguments per invocation is not limited except by `-m`; whichever limit is
  reached first applies.

Arguments:

* *callback*: Call the *callback* command with the collected arguments each
  time *quantum* lines are read. The callback command may be a shell function or
  any other kind of command, and is executed from the same shell environment
  that invoked `mapr`. If the callback command exits or returns with status
  255 or is interrupted by the `SIGPIPE` signal, `mapr` will not process any
  further batches but immediately exit with the status of the callback
  command. If it exits with another exit status 126 or greater, a
  [fatal error](#user-content-reliable-emergency-halt)
  is thrown. Otherwise, `mapr` exits with the status of the last-executed
  callback command.
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
* If the callback command exits with status 255, processing is aborted.

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

### `use var/readf` ###

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
encoded to `\n` to protect it from being stripped by command substitutions.

Usage: `readf` [ `-h` ] *varname*

The `-h` option disables conversion of high-byte characters (accented letters,
non-Latin scripts). Do not use for binary files; this is only guaranteed to
work for text files in an encoding compatible with the current locale.

Caveats:
* Best for small-ish files. The encoded file is stored in memory (a shell
  variable). For a binary file, encoding in `printf` format typically
  about doubles the size, though it could be up to four times as large.
* If the shell executing your program does not have `printf` as a builtin
  command, the external `printf` command will fail if the encoded file
  size exceeds the maximum length of arguments to external commands
  (`getconf ARG_MAX` will obtain this limit for your system). Shell builtin
  commands do not have this limit. Check for a `printf` builtin using
  [`thisshellhas`](#user-content-shell-capability-detection) if you need to be sure,
  and always [`harden`](#user-content-use-syscmdharden)
  `printf`!

### `use var/shellquote` ###

This module provides an efficient, fast, safe and portable shellquoting
algorithm for quoting arbitrary data in such a way that the quoted values are
safe to pass to the shell for parsing as string literals. This is essential
for any context where the shell must grammatically parse untrusted input,
such as when supplying arbitrary values to `trap` or `eval`.

The shellquoting algorithm is optimised to minimise exponential growth when
quoting repeatedly. By default, it also ensures that quoted strings are
always one single printable line, making them safe for terminal output and
processing by line-oriented utilities.

#### `shellquote` ####
Usage: `shellquote` [ `-f`|`+f`|`-P`|`+P` ] *varname*[`=`*value*] ...

The values of the variables specified by name are shell-quoted and stored
back into those variables.
Repeating a variable name will add another level of shell-quoting.
If a `=` plus a *value* (which may be empty) is appended to the *varname*,
that value is shell-quoted and assigned to the variable.

Options modify the algorithm for variable names following them, as follows:

* By default, newlines and any control characters are converted into
  [`${CC*}`](#user-content-control-character-whitespace-and-shell-safe-character-constants)
  expansions and quoted with double quotes, ensuring that the quoted string
  consists of a single line of printable text. The `-P` option forces pure
  POSIX quoted strings that may span multiple lines; `+P` turns this back off.

* By default, a value is only quoted if it contains characters not present
  in `$SHELLSAFECHARS`. The `-f` option forces unconditional quoting,
  disabling optimisations that may leave shell-safe characters unquoted;
  `+f` turns this back off.

`shellquote` will [die](#user-content-reliable-emergency-halt) if you
attempt to quote an unset variable (because there is no value to quote).

#### `shellquoteparams` ####
The `shellquoteparams` command shell-quotes the current positional
parameters in place using the default quoting method of `shellquote`. No
options are supported and any attempt to add arguments results in a syntax
error.

### `use var/stack` ###

Modules that extend [the stack](#user-content-the-stack).

#### `use var/stack/extra` ####
This module contains stack query and maintenance functions.

If you only need one or two of these functions, they can also be loaded as
individual submodules of `var/stack/extra`.

For the four functions below, *item* can be:
* a valid portable variable name
* a short-form shell option: dash plus letter
* a long-form shell option: `-o` followed by an option name (two arguments)
* `--trap=`*SIGNAME* to refer to the trap stack for the indicated signal
  (this requires the [`var/stack/trap`](#user-content-use-varstacktrap) module)

`stackempty` [ `--key=`*value* ] [ `--force` ] *item*: Tests if the stack
for an item is empty. Returns status 0 if it is, 1 if it is not. The key
feature works as in [`pop`](#user-content-the-stack): by default, a key
mismatch is considered equivalent to an empty stack. If `--force` is given,
this function ignores keys altogether.

`clearstack` [ `--key=`*value* ] [ `--force` ] *item* [ *item* ... ]:
Clears one or more stacks, discarding all items on it.
If (part of) the stack is keyed or a `--key` is given, only clears until a
key mismatch is encountered. The `--force` option overrides this and always
clears the entire stack (be careful, e.g. don't use within
[`LOCAL` ... `BEGIN` ... `END`](#user-content-use-varlocal)).
Returns status 0 on success, 1 if that stack was already empty, 2 if
there was nothing to clear due to a key mismatch.

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

#### `use var/stack/trap` ####
This module provides `pushtrap` and `poptrap`. These functions integrate
with the [main modernish stack](#user-content-the-stack)
to make traps stack-based, so that each
program component or library module can set its own trap commands without
interfering with others.

This module also provides the `--sig=` option to
[`thisshellhas`](#user-content-shell-capability-detection),
as well as a new
[`DIE` pseudosignal](#user-content-the-new-die-pseudosignal)
that allows pushing traps to execute when
[`die`](#user-content-reliable-emergency-halt)
is called.

Note an important difference between the trap stack and stacks for variables
and shell options: pushing traps does not save them for restoring later, but
adds them alongside other traps on the same signal. All pushed traps are
active at the same time and are executed from last-pushed to first-pushed
when the respective signal is triggered. Traps cannot be pushed and popped
using `push` and `pop` but use dedicated commands as follows.

Usage:

* `pushtrap` [ `--key=`*value* ] [ `--nosubshell` ] [ `--` ] *command* *sigspec* [ *sigspec* ... ]
* `poptrap` [ `--key=`*value* ] [ `-R` ] [ `--` ] *sigspec* [ *sigspec* ... ]

`pushtrap` works like regular `trap`, with the following exceptions:

* Adds traps for a signal without overwriting previous ones.
* An invalid signal is a fatal error. When using non-standard signals, check if
  [`thisshellhas --sig=`*yoursignal*](#user-content-shell-capability-detection)
  before using it.
* Unlike regular traps, a stack-based trap does not cause a signal to be
  ignored. Setting one will cause it to be executed upon the shell receiving
  that signal, but after the stack traps complete execution, modernish re-sends
  the signal to the main shell, causing it to behave as if no trap were set
  (unless a regular POSIX trap is also active).
  Thus, `pushtrap` does not accept an empty *command* as it would be pointless.
* Each stack trap is executed in a new subshell to keep it from interfering
  with others. This means a stack trap cannot change variables except within
  its own environment, and `exit` will only exit the trap and not the program.
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
last-pushed trap for each signal off the stack. By default, it discards
the trap commands. If the `-R` option is given, it stores commands to
restore those traps into the `REPLY` variable, in a format suitable for
re-entry into the shell. Again, the `--key` option works as in
[plain `pop`](#user-content-the-stack).

With the sole exception of
[`DIE` traps](#user-content-the-new-die-pseudosignal),
all stack-based traps, like native shell traps, are reset upon entering a
subshell (such as a command substitution or a series of commands enclosed in
parentheses). However, commands for printing traps will print the traps for
the parent shell, until another `trap`, `pushtrap` or `poptrap` command is
invoked, at which point all memory of the parent shell's traps is erased.

##### Trap stack compatibility considerations #####
Modernish tries hard to avoid incompatibilities with existing trap practice.
To that end, it intercepts the regular POSIX `trap` command using an alias,
reimplementing and interfacing it with the shell's builtin trap facility
so that plain old regular traps play nicely with the trap stack. You should
not notice any changes in the POSIX `trap` command's behaviour, except for
the following:

* The regular `trap` command does not overwrite stack traps (but still
  overwrites existing regular traps).
* Unlike zsh's native trap command, signal names are case insensitive.
* Unlike dash's native trap command, signal names may have the `SIG` prefix;
  that prefix is quietly accepted and discarded.
* Setting an empty trap action to ignore a signal only works fully (passing
  the ignoring on to child processes) if there are no stack traps associated
  with the signal; otherwise, an empty trap action merely suppresses the
  signal's default action for the current process – e.g., after executing
  the stack traps, it keeps the shell from exiting.
* The `trap` command with no arguments, which prints the traps that are set
  in a format suitable for re-entry into the shell, now also prints the
  stack traps as `pushtrap` commands. (`bash` users might notice the `SIG`
  prefix is not included in the signal names written.)
* The bash/yash-style `-p` option, including its yash-style `--print`
  equivalent, is now supported on all shells. If further arguments are
  given after that option, they are taken as signal specifications and
  only the commands to recreate the traps for those signals are printed.
* Saving the traps to a variable using command substitution (as in:
  `var=$(trap)`) now works on every
  [shell supported by modernish](#user-content-appendix-d-supported-shells),
  including (d)ash, mksh and zsh which don't support this natively.
* To reset (unset) a trap, the modernish `trap` command accepts both
  [valid POSIX syntax](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_28_03)
  and legacy bash/(d)ash/zsh syntax, like `trap INT` to unset a `SIGINT`
  trap (which only works if the `trap` command is given exactly one
  argument). Note that this is for compatibility with existing scripts only.
* Bypassing the `trap` alias to set a trap using the shell builtin command
  will cause an inconsistent state. This may be repaired with a simple `trap`
  command; as modernish prints the traps, it will quietly detect ones it
  doesn't yet know about and make them work nicely with the trap stack.

POSIX traps for each signal are always executed after that signal's stack-based
traps; this means they should not rely on modernish modules that use the trap
stack to clean up after themselves on exit, as those cleanups would already
have been done.

##### The new `DIE` pseudosignal #####
The `var/stack/trap` module adds new `DIE` pseudosignal whose traps are
executed upon invoking [`die`](#user-content-reliable-emergency-halt).
This allows for emergency cleanup operations upon fatal program failure,
as `EXIT` traps cannot be executed after `die` is invoked.

* On non-interactive shells, `DIE` is its own pseudosignal with its own trap
  stack and POSIX trap. In order to kill the malfunctioning program as quickly
  as possible (hopefully before it has a chance to delete all your data), `die`
  doesn't wait for those traps to complete before killing the program. Instead,
  it executes each `DIE` trap simultaneously as a background job, then gathers
  the process IDs of the main shell and all its subprocesses, sending `SIGKILL`
  to all of them except any `DIE` trap processes. Unlike other traps, `DIE`
  traps are inherited by and survive in subshell processes, and `pushtrap` may
  add to them within the subshell. Whatever shell process invokes `die` will
  fork all `DIE` trap actions before being `SIGKILL`ed itself. (Note that any
  `DIE` traps pushed or set within a subshell will still be forgotten upon
  exiting the subshell.)
* On interactive shells, `DIE` is simply an alias for `INT`, and `INT` traps
  (both POSIX and stack) are cleared out after executing them once. This is
  because `die` uses `SIGINT` for command interruption on interactive shells, and
  it would not make sense to execute emergency cleanup commands repeatedly. As
  a side effect of this special handling, `INT` traps on interactive shells do
  not have access to the positional parameters and cannot return from shell
  functions.

### `use var/string` ###

String comparison and manipulation functions.

#### `use var/string/touplow` ####
`toupper` and `tolower`: convert case in variables.

Usage:
* `toupper` *varname* [ *varname* ... ]
* `tolower` *varname* [ *varname* ... ]

Arguments are taken as variable names (note: they should be given without
the `$`) and case is converted in the contents of the specified variables,
without reading input or writing output.

`toupper` and `tolower` try hard to use the fastest available method on the
particular shell your program is running on. They use built-in shell
functionality where available and working correctly, otherwise they fall back
on running an external utility.

Which external utility is chosen depends on whether the current locale uses
the Unicode UTF-8 character set or not. For non-UTF-8 locales, modernish
assumes the POSIX/C locale and `tr` is always used. For UTF-8 locales,
modernish tries hard to find a way to correctly convert case even for
non-Latin alphabets. A few shells have this functionality built in with
`typeset`. The rest need an external utility. Modernish initialisation
tries `tr`, `awk`, GNU `awk` and GNU `sed` before giving up and setting
the variable `MSH_2UP2LOW_NOUTF8`. If `isset MSH_2UP2LOW_NOUTF8`, it
means modernish is in a UTF-8 locale but has not found a way to convert
case for non-ASCII characters, so `toupper` and `tolower` will convert
only ASCII characters and leave any other characters in the string alone.

#### `use var/string/trim` ####
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

#### `use var/string/replacein` ####
`replacein`: Replace leading, `-t`railing or `-a`ll occurrences of a string by
another string in a variable.    
Usage: `replacein` [ `-t` | `-a` ] *varname* *oldstring* *newstring*

#### `use var/string/append` ####
`append` and `prepend`: Append or prepend zero or more strings to a
variable, separated by a string of zero or more characters, avoiding the
hairy problem of dangling separators.
Usage: `append`|`prepend` [ `--sep=`*separator* ] [ `-Q` ] *varname* [ *string* ... ]    
If the separator is not specified, it defaults to a space character.
If the `-Q` option is given, each *string* is
[shell-quoted](#user-content-use-varshellquote)
before appending or prepending.

### `use var/unexport` ###

The `unexport` function clears the "export" bit of a variable, conserving
its value, and/or assigns values to variables without setting the export
bit. This works even if `set -a` (allexport) is active, allowing an "export
all variables, except these" way of working.

Usage is like `export`, with the caveat that variable assignment arguments
containing non-shellsafe characters or expansions must be quoted as
appropriate, unlike in some specific shell implementations of `export`.
(To get rid of that headache, [`use safe`](#user-content-use-safe).)

Unlike `export`, `unexport` does not work for read-only variables.

### `use var/genoptparser` ###

As the `getopts` builtin is not portable when used in functions, this module
provides a command that generates modernish code to parse options for your
shell function in a standards-compliant manner. The generated parser
supports short-form (one-character) options which can be stacked/combined.

Usage:
`generateoptionparser` [ `-o` ] [ `-f` *func* ] [ `-v` *varprefix* ]
[ `-n` *options* ] [ -a *options* ] [ *varname* ]

* `-o`: Write parser to standard output.
* `-f`: Function name to prefix to error messages. Default: none.
* `-v`: Variable name prefix for options. Default: `opt_`.
* `-n`: String of options that do not take arguments.
* `-a`: String of options that require arguments.
* *varname*: Store parser in specified variable. Default: `REPLY`.

At least one of `-n` and `-a` is required. All other arguments are optional.
Option characters must be valid components of portable variable names, so
they must be ASCII upper- or lowercase letters, digits, or the underscore.

`generateoptionparser` stores the generated parser code in a variable: either
`REPLY` or the *varname* specified as the first non-option argument. This makes
it possible to generate and use the parser on the fly with a command like
`eval "$REPLY"` immediately following the `generateoptionparser` invocation.

For better efficiency and readability, it will often be preferable to insert
the option parser code directly into your shell function instead. The `-o`
option writes the parser code to standard output, so it can be redirected to
a file, inserted into your editor, etc.

Parsed options are shifted out of the positional parameters while setting or
unsetting corresponding variables, until a non-option argument, a `--`
end-of-options delimiter argument, or the end of arguments is encountered.
Unlike with `getopts`, no additional `shift` command is required.

Each specified option gets a corresponding variable with a name consisting
of the *varprefix* (default: `opt_`) plus the option character. If an option
is not passed to your function, the parser unsets its variable; otherwise it
sets it to either the empty value or its option-argument if it requires one.
Thus, your function can check if any option `x` was given using
[`isset`](#user-content-isset),
for example, `if isset opt_x; then`...

### `use sys/base` ###

Some very common and essential utilities are not specified by POSIX, differ
widely among systems, and are not always available. For instance, the
`which` and `readlink` commands have incompatible options on various GNU and
BSD variants and may be absent on other Unix-like systems. The `sys/base`
module provides a complete re-implementation of such non-standard but basic
utilities, written as modernish shell functions. Using the modernish version
of these utilities can help a script to be fully portable. These versions
also have various enhancements over the GNU and BSD originals, some of which
are made possible by their integration into the modernish shell environment.

#### `use sys/base/mktemp` ####
A cross-platform shell implementation of `mktemp` that aims to be just as
safe as native `mktemp`(1) implementations, while avoiding the problem of
having various mutually incompatible versions and adding several unique
features of its own.

Creates one or more unique temporary files, directories or named pipes,
atomically (i.e. avoiding race conditions) and with safe permissions.
The path name(s) are stored in `REPLY` and optionally written to stdout.

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
        `SIGPIPE` and `SIGTERM` as well. On receiving `SIGINT`, clean up if the
        option was given at least twice, otherwise notify the user of files
        left. On the invocation of
        [`die`](#user-content-reliable-emergency-halt),
        clean up if the option was given at least three times, otherwise notify
        the user of files left.
* `-t`: Prefix one temporary files directory to all the *template*s:
        `$TMPDIR/` if `TMPDIR` is set, `/tmp/` otherwise. The *template*s
        may not contain any slashes. If the template has neither any trailing
        `X`es nor a trailing dot, a dot is added before the random suffix.

The template defaults to “`/tmp/temp.`”. An suffix of random shell-safe ASCII
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

This module depends on the trap stack to do autocleanup (the `-C` option),
so it will automatically `use var/stack/trap` on initialisation.

#### `use sys/base/readlink` ####
`readlink` reads the target of a symbolic link, robustly handling strange
filenames such as those containing newline characters. It stores the result
in the `REPLY` variable and optionally writes it on standard output.

Usage: `readlink` [ `-nsfQ` ] *file* [ *file* ... ]

* `-n`: If writing output, don't add a trailing newline.
* `-s`: *S*ilent operation: don't write output, only store it in `REPLY`.
* `-f`: Canonicalise each path found, following all symlinks encountered, so
  the result is an absolute path that can be used starting from any working
  directory. For this mode, all but the last pathname component must exist.
* `-Q`: Shell-*q*uote each unit of output. Separate by spaces instead
  of newlines. This generates a list of arguments in shell syntax,
  guaranteed to be suitable for safe parsing by the shell, even if the
  resulting pathnames should contain strange characters such as spaces or
  newlines and other control characters.

#### `use sys/base/rev` ####
`rev` copies the specified files to the standard output, reversing the order
of characters in every line. If no files are specified, the standard input
is read.

Usage: like `rev` on Linux and BSD, which is like `cat` except that `-` is
a filename and does not denote standard input. No options are supported.

#### `use sys/base/seq` ####
A cross-platform implementation of `seq` that is more powerful and versatile
than native GNU and BSD `seq`(1) implementations. The core is written in
`bc`, the POSIX arbitrary-presision calculator language. That means this
`seq` inherits the capacity to handle numbers with a precision and size only
limited by computer memory, as well as the ability to handle input numbers
in any base from 1 to 16 and produce output in any base 1 and up.

Usage: `seq` [ `-w` ] [ `-L` ] [ `-f` *format* ] [ `-s` *string* ] [ `-S` *scale* ]
[ `-B` *base* ] [ `-b` *base* ] [ *first* [ *incr* ] ] *last*

`seq` prints a sequence of arbitrary-precision floating point numbers, one
per line, from *first* (default 1), to as near *last* as possible, in increments of
*incr* (default 1). If *first* is larger than *last*, the default *incr* is -1.
An *incr* of zero is treated as a fatal error.

* `-w`: Equalise width by padding with leading zeros. The longest of the
	*first*, *incr* or *last* arguments is taken as the length that each
	output number should be padded to.
* `-L`: Use the current locale's radix point in the output instead of the
        full stop (`.`).
* `-f`: `printf`-style floating-point format. The format string is passed on
        (with an added `\n`) to `awk`'s builtin `printf` function. Because
        of that, the `-f` option can only be used if the output base is 10.
        Note that `awk`'s floating point precision is limited, so very
        large or long numbers will be rounded.
* `-s`: Instead of writing one number per line, write all numbers on one
        line separated by *string* and terminated by a newline character.
* `-S`: Explicitly set the scale (number of digits after the
        [radix point](https://en.wikipedia.org/wiki/Radix_point)).
	Defaults to the largest number of digits after the radix point
	among the *first*, *incr* or *last* arguments.
* `-B`: Set input and output base from 1 to 16. Defaults to 10.
* `-b`: Set arbitrary output base from 1. Defaults to input base.
        See the `bc`(1) manual for more information on the output format
        for bases greater than 16.

The `-S`, `-B` and `-b` options take shell integer numbers as operands. This
means a leading `0X` or `0x` denotes a hexadecimal number and a leading `0`
denotes an octal numnber.

For portability reasons, modernish `seq` uses a full stop (`.`) for the
[radix point](https://en.wikipedia.org/wiki/Radix_point), regardless of the
system locale. This applies both to command arguments and to output.
The `-L` option causes `seq` to use the current locale's radix point
character for output only.

##### Differences with GNU and BSD `seq` #####
The `-S`, `-B` and `-b` options are modernish innovations.
The `-w`, `-f` and `-s` options are inspired by GNU and BSD `seq`.
The following differences apply:

* Like GNU and unlike BSD, the separator specified by the `-s` option
  is not appended to the final number and there is no `-t` option to
  add a terminator character.
* Like GNU and unlike BSD, the `-s` option-argument is taken as literal
  characters and is not parsed for backslash escape codes like `\n`.
* Unlike GNU and like BSD, the output radix point defaults to a full stop,
  regardless of the current locale.
* Unlike GNU and like BSD, if *incr* is not specified,
  it defaults to -1 if *first* > *last*, 1 otherwise.
  For example, `seq 5 1` counts backwards from 5 to 1, and
  specifying `seq 5 -1 1` as with GNU is not needed.
* Unlike GNU and like BSD, an *incr* of zero is not accepted.
  To output the same number or string infinite times, use
  [`yes`](#user-content-use-sysbaseyes) instead.
* Unlike both GNU and BSD, the `-f` option accepts any format specifiers
  accepted by `awk`'s `printf()` function.

The `sys/base/seq` module depends on, and automatically loads,
[`var/string/touplow`](#user-content-use-varstringtouplow).

#### `use sys/base/shuf` ####
Shuffle lines of text.
A portable reimplementation of a commonly used GNU utility.

Usage:

* `shuf` [ `-n` *max* ] [ `-r` *rfile* ] *file*
* `shuf` [ `-n` *max* ] [ `-r` *rfile* ] `-i` *low*`-`*high*
* `shuf` [ `-n` *max* ] [ `-r` *rfile* ] `-e` *argument* ...

By default, `shuf` reads lines of text from standard input, or from *file*
(the *file* `-` signifies standard input).
It writes the input lines to standard output in random order.

* `-i`: Use sequence of non-negative integers *low* through *high* as input.
* `-e`: Instead of reading input, use the *argument*s as lines of input.
* `-n`: Output a maximum of *max* lines.
* `-r`: Use *rfile* as the source of random bytes. Defaults to `/dev/urandom`.

Differences with GNU `shuf`:

* Long option names are not supported.
* The `-o`/`--output-file` option is not supported; use output redirection.
  Safely shuffling files in-place is not supported; use a temporary file.
* `--random-source=`*file* is changed to `-r` *file*.
* The `-z`/`--zero-terminated` option is not supported.

#### `use sys/base/tac` ####
`tac` (the reverse of `cat`) is a cross-platform reimplementation of the GNU
`tac` utility, with some extra features.

Usage: `tac` [ `-rbBP` ] [ `-S` *separator* ] *file* [ *file* ... ]

`tac` outputs the *file*s in reverse order of lines/records.
If *file* is `-` or is not given, `tac` reads from standard input.

* `-s`: Specify the record (line) separator. Default: linefeed.
* `-r`: Interpret the record separator as an
  [extended regular expression](http://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap09.html#tag_09_04).
  This allows using separators that may vary. Each separator is preserved
  in the output as it is in the input.
* `-b`: Assume the separator comes before each record in the input, and also
  output the separator before each record. Cannot be combined with `-B`.
* `-B`: Assume the separator comes after each record in the input, but output
  the separator before each record. Cannot be combined with `-b`.
* `-P`: Paragraph mode: output text last paragraph first. Input paragraphs
  are separated from each other by at least two linefeeds. Cannot be combined
  with any other option.

Differences between GNU `tac` and modernish `tac`:
* The `-B` and `-P` options were added.
* The `-r` option interprets the record separator as an extended regular
  expression. This is an incompatibility with GNU `tac` unless expressions
  are used that are valid as both basic and extended regular expressions.
* In UTF-8 locales, multibyte characters are recognised and reversed
  correctly.

#### `use sys/base/which` ####
The modernish `which` utility finds external programs and reports their
absolute paths, offering several unique options for reporting, formatting
and robust processing. The default operation is similar to GNU `which`.

Usage: `which` [ `-apqsnQ1f` ] [ `-P` *number* ] *program* [ *program* ... ]

By default, `which` finds the first available path to each given *program*.
If *program* is itself a path name (contains a slash), only that path's base
directory is searched; if it is a simple command name, the current `$PATH`
is searched. Any relative paths found are converted to absolute paths.
Symbolic links are not followed. The first path found for each *program* is
written to standard output (one per line), and a warning is written to
standard error for every *program* not found. The exit status is 0 (success)
if all *program*s were found, 1 otherwise.

`which` also leaves its output in the `REPLY` variable. This may be useful
if you run `which` in the main shell environment. The `REPLY` value will
*not* survive a command substitution subshell as in `ls_path=$(which ls)`.

The following options modify the default behaviour described above:

* `-a`: List *a*ll *program*s that can be found in the directories searched,
  instead of just the first one. This is useful for finding duplicate
  commands that the shell would not normally find when searching its `$PATH`.
* `-p`: Search in [`$DEFPATH`](#user-content-modernish-system-constants)
  (the default standard utility `PATH` provided by the operating system)
  instead of in the user's `$PATH`, which is vulnerable to manipulation.
* `-q`: Be *q*uiet: suppress all warnings.
* `-s`: *S*ilent operation: don't write output, only store it in the `REPLY`
  variable. Suppress warnings except, if you run `which -s` in a subshell,
  a warning that the `REPLY` variable will not survive the subshell.
* `-n`: When writing to standard output, do *n*ot write a final *n*ewline.
* `-Q`: Shell-*q*uote each unit of output. Separate by spaces instead
  of newlines. This generates a one-line list of arguments in shell syntax,
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
  returns successfully if at least one command was found.
* `-f`: Throw a [*f*atal error](#user-content-reliable-emergency-halt)
  in cases where `which` would otherwise return status 1 (non-success).
* `-P`: Strip the indicated number of *p*athname elements from the output,
  starting from the right.
  `-P1`: strip `/program`;
  `-P2`: strip `/*/program`,
  etc. This is useful for determining the installation root directory for
  an installed package.
* `--help`: Show brief usage information.

#### `use sys/base/yes` ####
`yes` very quickly outputs infinite lines of text, each consisting of its
space-separated arguments, until terminated by a signal or by a failure to
write output. If no argument is given, the default line is `y`. No options
are supported.

This infinite-output command is useful for piping into commands that need an
indefinite input data stream, or to automate a command requiring interactive
confirmation.

Modernish `yes` is like GNU `yes` in that it outputs all its arguments,
whereas BSD `yes` only outputs the first. It can output multiple gigabytes
per second on modern systems.

### `use sys/cmd` ###

Modules in this category contain functions for enhancing the invocation of
commands.

#### `use sys/cmd/extern` ####
`extern` is like `command` but always runs an external command, without
having to know or determine its location. This provides an easy way to
bypass a builtin, alias or function. It does the same `$PATH` search
the shell normally does when running an external command. For instance, to
guarantee running external `printf` just do: `extern printf ...`

Usage: `extern` [ `-p` ] [ `-v` ] [ `-u` *varname* ... ]
[ *varname*`=`*value* ... ] *command* [ *argument* ... ]

* `-p`: The *command*, as well as any commands it further invokes, are searched in
  [`$DEFPATH`](#user-content-modernish-system-constants)
  (the default standard utility `PATH` provided by the operating system)
  instead of in the user's `$PATH`, which is vulnerable to manipulation.
  * `extern -p` is much more reliable than the shell's builtin
    [`command -p`](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/command.html#tag_20_22_04)
    because: (a) many existing shell installations use a wrong search path for
    `command -p`; (b) `command -p` does not export the default `PATH`, so
    something like `command -p sudo cp foo /bin/bar` searches only `sudo` in
    the secure default path and not `cp`.
* `-v`: don't execute *command* but show the full path name of the command that
  would have been executed. Any extra *argument*s are taken as more command
  paths to show, one per line. `extern` exits with status 0 if all the commands
  were found, 1 otherwise. This option can be combined with `-p`.
* `-u`: Temporary export override. Unset the given variable in the
  environment of the command executed, even if it is currently exported. Can
  be specified multiple times.
* *varname*`=`*value* assignment-arguments: These variables/values are
  temporarily exported to the environment during the execution of the command.
  * This is provided because assignments *preceding* `extern` cause unwanted,
    shell-dependent side effects, as `extern` is a shell function. Be
    sure to provide assignment-arguments *following* `extern` instead.
  * Assignment-arguments after a `--` end-of-options delimiter are not parsed;
    this allows *command*s containing a `=` sign to be executed.

#### `use sys/cmd/harden` ####
The `harden` function allows implementing emergency halt on error
for any external commands and shell builtin utilities. It is
modernish's replacement for `set -e` a.k.a. `set -o errexit` (which is
[fundamentally](https://lists.gnu.org/archive/html/bug-bash/2012-12/msg00093.html)
[flawed](http://mywiki.wooledge.org/BashFAQ/105),
not supported and will break the library).
It depends on, and auto-loads, the `sys/cmd/extern` module.

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
mandatory.) If *command_name_or_path* is itself a shell function, that
function is bypassed and the builtin or external command by that name is
hardened instead. If no such command is found, `harden` dies with the message
that hardening shell functions is not supported. (Instead, you should invoke
`die` directly from your shell function upon detecting a fatal error.)

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
least twice, the command is run in a subshell with `PATH` exported as the
default path, which is equivalent to adding a `PATH=$DEFPATH` assignment
argument (see [below](#user-content-important-note-on-variable-assignments)).

Examples:

```sh
harden make                           # simple check for status > 0
harden -f tar '/usr/local/bin/gnutar' # id.; be sure to use this 'tar' version
harden -e '> 1' grep                  # for grep, status > 1 means error
harden -e '==1 || >2' gzip            # 1 and >2 are errors, but 2 isn't (see manual)
```

##### Important note on variable assignments #####
As far as the shell is concerned, hardened commands are shell functions and
not external or builtin commands. This essentially changes one behaviour of
the shell: variable assignments preceding the command will not be local to
the command as usual, but *will persist* after the command completes.
(POSIX technically makes that behaviour
[optional](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_09_01)
but all current shells behave the same in POSIX mode.)

For example, this means that something like

```sh
harden -e '>1' grep
# [...]
LC_ALL=C grep regex some_ascii_file.txt
```

should never be done, because the meant-to-be-temporary `LC_ALL` locale
assignment will persist and is likely to cause problems further on.

To solve this problem, `harden` supports adding these assignments as
part of the hardening command, so instead of the above you do:

```sh
harden -e '>1' LC_ALL=C grep
# [...]
grep regex some_ascii_file.txt
```

With the `-u` option, `harden` also supports unsetting variables for the
duration of a command, e.g.:

```sh
harden -e '>1' -u LC_ALL grep
```

Pitfall alert: if the `-u` option is used, this causes the hardened command to
run in a subshell with those variables unset, because using a subshell is the
only way to avoid altering those variables' state in the main shell. This is
usually fine, but note that a builtin command hardened with use of `-u` cannot
influence the calling shell. For instance, something like `harden -u LC_ALL cd`
renders `cd` ineffective: the working directory is only changed within the
subshell which is then immediately left.

##### Hardening while allowing for broken pipes #####
If you're piping a command's output into another command that may close
the pipe before the first command is finished, you can use the `-P` option
to allow for this:

```sh
harden -e '==1 || >2' -P gzip		# also tolerate gzip being killed by SIGPIPE
gzip -dc file.txt.gz | head -n 10	# show first 10 lines of decompressed file
```

`head` will close the pipe of `gzip` input after ten lines; the operating
system kernel then kills `gzip` with the PIPE signal before it's finished,
causing a particular exit status that is greater than 128. This exit status
would normally make `harden` kill your entire program, which in the example
above is clearly not the desired behaviour. If the exit status caused by a
broken pipe were known, you could specifically allow for that exit status in
the status expression. The trouble is that this exit status varies depending
on the shell and the operating system. The `-p` option was made to solve
this problem: it automatically detects and whitelists the correct exit
status corresponding to `SIGPIPE` termination on the current system.

Tolerating `SIGPIPE` is an option and not the default, because in many
contexts it may be entirely unexpected and a symptom of a severe error if a
command is killed by a broken pipe. It is up to the programmer to decide
which commands should expect `SIGPIPE` and which shouldn't.

*Tip:* It could happen that the same command should expect `SIGPIPE` in one
context but not another. You can create two hardened versions of the same
command, one that tolerates `SIGPIPE` and one that doesn't. For example:

```sh
harden -f hardGrep -e '>1' grep		# hardGrep does not tolerate being aborted
harden -f pipeGrep -e '>1' -P grep	# pipeGrep for use in pipes that may break
```

*Note:* If `SIGPIPE` was set to ignore by the process invoking the current
shell, the `-p` option has no effect, because no process or subprocess of
the current shell can ever be killed by `SIGPIPE`. However, this may cause
various other problems and you may want to refuse to let your program run
under that condition.
[`thisshellhas WRN_NOSIGPIPE`](#user-content-warning-ids) can help
you easily detect that condition so your program can make a decision. See
the [`WRN_NOSIGPIPE` description](#user-content-warnig-ids) for more information.

##### Tracing the execution of hardened commands #####
The `-t` option will trace command output. Each execution of a command
hardened with `-t` causes the command line to be output to standard
error, in the following format:

    [functionname]> commandline

where `functionname` is the name of the shell function used to harden the
command and `commandline` is the actual command executed. The
`commandline` is properly shell-quoted in a format suitable for re-entry
into the shell; however, command lines longer than 512 bytes will be
truncated and the unquoted string ` (TRUNCATED)` will be appended to the
trace. If standard error is on a terminal that supports ANSI colours,
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

##### Simple tracing of commands #####
Sometimes you just want to trace the execution of some specific commands as
in `harden -t` (see above) without actually hardening them against command
errors; you might prefer to do your own error handling. `trace` makes this
easy. It is modernish's replacement or complement for `set -x` a.k.a. `set
-o xtrace`.
Unlike `harden -t`, it can also trace shell functions.

**Usage 1:** `trace` [ `-f` *funcname* ] [ `-[cSpXE]` ]
[ *var*`=`*value* ... ] [ `-u` *var* ... ] *command_name_or_path*
[ *command_argument* ... ]

For non-function commands, `trace` acts as a shortcut for
`harden -t -P -e '>125 && !=255'` *command_name_or_path*.
Any further options and arguments are passed on to `harden` as given. The
result is that the indicated command is automatically traced upon execution.
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

**Usage 2:** [ `#!` ] `trace -f` *funcname*

If no further arguments are given, `trace -f` will trace the shell
function *funcname* without applying further hardening (except against
nonexistence). `trace -f` can be used to trace the execution of modernish
library functions as well as your own script's functions. The trace output
for shell functions shows an extra `()` following the function name.

Internally, this involves setting an alias under the function's name, so
the limitations of the shell's alias expansion mechanism apply: only
function calls that the shell had not yet parsed before calling `trace -f`
will be traced. So you should use `trace -f` at the beginning of your
script, before defining your own functions. To facilitate this, `trace -f`
does not check that the function *funcname* exists while setting up
tracing, but only when attempting to execute the traced function.

In [portable-form](#user-content-portable-form)
modernish scripts, `trace -f` should be used as a hashbang command to be
compatible with alias expansion on all shells. Only the `trace -f` form
may be used that way. For example:

```sh
#! /usr/bin/env modernish
#! use safe -k
#! use sys/cmd/harden
#! trace -f push
#! trace -f pop
...your program begins here...
```

#### `use sys/cmd/procsubst` ####
This module provides a portable
[process substitution](https://en.wikipedia.org/wiki/Process_substitution)
construct, the advantage being that this is not limited to bash, ksh or zsh
but works on all POSIX shells capable of running modernish. It is not
possible for modernish to introduce the original ksh syntax into other
shells. Instead, this module provides a `%` command for use within a command
substitution, either `$(%` modern form`)` or the legacy form with backticks.

The `%` command takes one simple command as its arguments, executes it in
the background, and writes a file name from which to read its output. So
if `%` is used within a command substitution as intended, that file name
is passed on to the current command. If it is used as a standalone command,
the command it launches will be suspended and wait in the background until
something reads data from the file name it outputs.

The `%` command supports one option, `-o`. If that option is given, it is
expected that output is written to the file name written by `%`, instead of
input read from it.

<table>
<caption>Example syntax comparison:</caption>
<tr>
<th>ksh/bash/zsh</th><th>modernish</th>
</tr>
<tr>
<td valign="top">
<code>diff -u <(ls) <(ls -a)</code>
</td>
<td>
<code>diff -u $(% ls) $(% ls -a)</code>
<br/>
<code>diff -u `% ls` `% ls -a`</code>
</td>
</tr>
<tr>
<td valign="top">
<code>pax -wf >(compress -c >$dir.pax.Z) $dir</code>
</td>
<td>
<code>pax -wf $(% -o eval 'compress -c > $dir.pax.Z') $dir</code>
<br/>
<code>pax -wf `% -o eval 'compress -c > $dir.pax.Z'` $dir</code>
</td>
</tr>
</table>

Unlike the bash/ksh/zsh version, modernish process substitution only works
with simple commands. This includes shell function calls, but not aliases or
anything involving shell grammar or reserved words (such as loops or
conditionals). To use such complex commands, enclose them in a shell
function and call that function from the process substitution.

#### `use sys/cmd/source` ####
The `source` command sources a dot script like the `.` command, but
additionally supports passing arguments to sourced scripts like you would
pass them to a function.

This command is built in to bash and zsh, but this module adds it to other
shells. The module will not override an existing `source` builtin.

If a filename without a directory path is given, then, unlike the `.`
command, `source` looks for the dot script in the current directory by
default, as well as searching `$PATH`.

### `use sys/dir` ###

Functions for working with directories.

#### `use sys/dir/countfiles` ####
`countfiles`: Count the files in a directory using nothing but shell
functionality, so without external commands. (It's amazing how many pitfalls
this has, so a library function is needed to do it robustly.)

Usage: `countfiles` [ `-s` ] *directory* [ *globpattern* ... ]

Count the number of files in a directory, storing the number in `REPLY`
and (unless `-s` is given) printing it to standard output.
If any *globpattern*s are given, only count the files matching them.

#### `use sys/dir/mkcd` ####
The `mkcd` function makes one or more directories, then, upon success,
change into the last-mentioned one. `mkcd` inherits `mkdir`'s usage, so
options depend on your system's `mkdir`; only the
[POSIX options](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/mkdir.html#tag_20_79_04)
are guaranteed.


### `use sys/term` ###

Utilities for working with the terminal.

#### `use sys/term/putr` ####
This module provides commands to efficiently output a string repeatedly.

Usage:

* `putr` [ *number* | `-` ] *string*
* `putrln` [ *number* | `-` ] *string*

Output the *string* *number* times. When using `putrln`, add a newline at
the end.


If a `-` is given instead of a *number*, then the total length of the output
is the line length of the terminal divided by the length of the *string*,
rounded down.

Note that, unlike with `put` and `putln`, only a single *string*
argument is accepted.

Example: `putrln - '='` prints a full terminal line of equals signs.

#### `use sys/term/readkey` ####
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

This module depends on the trap stack to save and restore the terminal state
if the program is stopped while reading a key, so it will automatically
`use var/stack/trap` on initialisation.

---

## Appendix A: List of shell cap IDs ##

This appendix lists all the shell
[capabilities](#user-content-capabilities),
[quirks](#user-content-quirks), and
[bugs](#user-content-bugs)
that modernish can detect in the current shell, so that modernish scripts
can easily query the results of these tests and decide what to do. Certain
[problematic system conditions](#user-content-warning-ids)
are also detected this way and listed here.

The all-caps IDs below are all usable with the
[`thisshellhas`](#user-content-shell-capability-detection)
function. This makes it easy for a cross-platform modernish script to
be aware of relevant conditions and decide what to do.

Each detection test has its own little test script in the
`lib/modernish/cap` directory. These tests are executed on demand, the
first time the capability or bug in question is queried using
`thisshellhas`. See `README.md` in that directory for further information.
The test scripts also document themselves in the comments.

### Capabilities ###

Modernish currently identifies and supports the following non-standard
shell capabilities:

* `ADDASSIGN`: Add a string to a variable using additive assignment,
  e.g. *VAR*`+=`*string*
* `ANONFUNC`: zsh anonymous functions (basically the native zsh equivalent
  of modernish's var/local module)
* `ARITHCMD`: standalone arithmetic evaluation using a command like
  `((`*expression*`))`.
* `ARITHFOR`: ksh93/C-style arithmetic `for` loops of the form
  `for ((`*exp1*`; `*exp2*`; `*exp3*`)) do `*commands*`; done`.
* `ARITHPP`: support for the `++` and `--` unary operators in shell arithmetic.
* `CESCQUOT`: Quoting with C-style escapes, like `$'\n'` for newline.
* `DBLBRACKET`: The ksh88-style `[[` double-bracket command `]]`,
  implemented as a reserved word, integrated into the main shell grammar,
  and with a different grammar applying within the double brackets.
  (ksh93, mksh, bash, zsh, yash >= 2.48)
* `DBLBRACKETERE`: `DBLBRACKET` plus the `=~` binary operator to match a
  string against an extended regular expression.
* `DBLBRACKETV`: `DBLBRACKET` plus the `-v` unary operator to test if a
  variable is set. Named variables only. (Testing positional parameters
  (like `[[ -v 1 ]]`) does not work on bash or ksh93; check `$#` instead.)
* `DOTARG`: Dot scripts support arguments.
* `HERESTR`: Here-strings, an abbreviated kind of here-document.
* `KSH88FUNC`: define ksh88-style shell functions with the `function` keyword,
  supporting dynamically scoped local variables with the `typeset` builtin.
  (mksh, bash, zsh, yash, et al)
* `KSH93FUNC`: the same, but with static scoping for local variables. (ksh93 only)
  See Q28 at the [ksh93 FAQ](http://kornshell.com/doc/faq.html) for an explanation
  of the difference.
* `KSHARRAY`: ksh93-style arrays. Supported on bash, zsh (under `emulate sh`),
  mksh, and ksh93.
* `LEPIPEMAIN`: execute last element of a pipe in the main shell, so that
  things like *somecommand* `| read` *somevariable* work. (zsh, AT&T ksh,
  bash 4.2+)
* `LINENO`: the `$LINENO` variable contains the current shell script line
  number.
* `LOCALVARS`: the `local` command creates local variables within functions
  defined using standard POSIX syntax.
* `NONFORKSUBSH`: as a performance optimisation, subshell environments are
  implemented without forking a new process, so they share a PID with the main
  shell. (AT&T ksh93; it has [many bugs](https://github.com/att/ast/issues/480)
  related to this, but there's a nice workaround: `ulimit -t unlimited` forces
  a subshell to fork, making those bugs disappear! See also `BUG_FNSUBSH`.)
* `PRINTFV`: The shell's `printf` builtin has the `-v` option to print to a variable,
  which avoids forking a command substitution subshell.
* `PSREPLACE`: Search and replace strings in variables using special parameter
  substitutions with a syntax vaguely resembling sed.
* `RANDOM`: the `$RANDOM` pseudorandom generator.
  Modernish seeds it if detected. The variable is then set it to read-only
  whether the generator is detected or not, in order to block it from losing
  its special properties by being unset or overwritten, and to stop it being
  used if there is no generator. This is because some of modernish depends
  on `RANDOM` either working properly or being unset.    
  (The use case for non-readonly `RANDOM` is setting a known seed to get
  reproducible pseudorandom sequences. To get that in a modernish script,
  use `awk`'s `srand(yourseed)` and `int(rand()*32768)`.)
* `ROFUNC`: Set functions to read-only with `readonly -f`. (bash, yash)
* `TESTO`: The `test`/`[` builtin supports the `-o` unary operator to check if 
  a shell option is set.
* `TRAPPRSUBSH`: The ability to obtain a list of the current shell's native
  traps from a command substitution subshell, for example: `var=$(trap)`.
  Note that modernish transparently reimplements this feature on shells
  without this native capability, so this feature ID is only relevant if you
  are bypassing modernish to access the `trap` builtin directly. Also, in
  order to be useful to modernish, this capability is only detected
  if the `trap` command in `var=$(trap)` can be replaced by a shell function
  that in turn calls the builtin `trap` command.
* `TRAPZERR`: This feature ID is detected if the `ERR` trap is an alias for
  the `ZERR` trap. According to the zsh manual, this is the case for zsh on
  most systems, i.e. those that don't have a `SIGERR` signal. (The
  [trap stack](#user-content-the-trap-stack)
  uses this feature test.)

### Quirks ###

Modernish currently identifies and supports the following shell quirks:

* `QRK_32BIT`: mksh: the shell only has 32-bit arithmetic. Since every modern
  system these days supports 64-bit long integers even on 32-bit kernels, we
  can now count this as a quirk.
* `QRK_ANDORBG`: On zsh, the `&` operator takes the last simple command
  as the background job and not an entire AND-OR list (if any).
  In other words, `a && b || c &` is interpreted as
  `a && b || { c & }` and not `{ a && b || c; } &`.
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
  [var/local](#user-content-use-varlocal)
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
* `QRK_IFSFINAL`: in field splitting, a final non-whitespace `IFS` delimiter
  character is counted as an empty field (yash \< 2.42, zsh, pdksh). This is a QRK
  (quirk), not a BUG, because POSIX is ambiguous on this.
* `QRK_LOCALINH`: On a shell with LOCALVARS, local variables, when declared
  without assigning a value, inherit the state of their global namesake, if
  any. (dash, FreeBSD sh)
* `QRK_LOCALSET`: On a shell with LOCALVARS, local variables are immediately set
  to the empty value upon being declared, instead of being initially without
  a value. (zsh)
* `QRK_LOCALSET2`: Like `QRK_LOCALSET`, but *only* if the variable by the
  same name in the global/parent scope is unset. If the global variable is
  set, then the local variable starts out unset. (bash 2 and 3)
* `QRK_LOCALUNS`: On a shell with LOCALVARS, local variables lose their local
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
* `QRK_OPTABBR`: Long-form shell option names can be abbreviated down to a
  length where the abbreviation is not redundant with other long-form option
  names. (ksh93, yash)
* `QRK_OPTCASE`: Long-form shell option names are case-insensitive. (yash, zsh)
* `QRK_OPTDASH`: Long-form shell option names ignore the `-`. (ksh93, yash)
* `QRK_OPTNOPRFX`: Long-form shell option names use a dynamic `no` prefix for
  all options (including POSIX ones). For instance, `glob` is the opposite
  of `noglob`, and `nonotify` is the opposite of `notify`. (ksh93, yash, zsh)
* `QRK_OPTULINE`: Long-form shell option names ignore the `_`. (yash, zsh)
* `QRK_PPIPEMAIN`: On zsh \<= 5.5.1, in all elements of a pipeline, parameter
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

Modernish currently identifies and supports the following shell bugs:

* `BUG_ALIASCSUB`: Inside a command substitution of the form `$(`...`)`,
  shell block constructs expanded from two or more aliases do not parse
  correctly on older mksh versions. This bug affects
  [`LOCAL`...`BEGIN`...`END`](#user-content-use-varlocal) and
  [`LOOP`...`DO`...`DONE`](#user-content-use-varloop).
  Workaround: when using these in a command substitution,
  either make sure the first statement after `BEGIN` or `DO`
  is on the same line as `BEGIN` or `DO`, or use the old
  `` ` ``backtick command substitution`` ` ``
  form which works correctly. Bug
  [found](https://www.mail-archive.com/miros-mksh@mirbsd.org/msg00749.html)
  in: mksh/lksh up to R54 (2016/11/11).
* `BUG_APPENDC`: When `set -C` (`noclobber`) is active, "appending" to a nonexistent
  file with `>>` throws an error rather than creating the file. (zsh \< 5.1)
  This is a bug making `use safe` less convenient to work with, as this sets
  the `-C` (`-o noclobber`) option to reduce accidental overwriting of files.
* `BUG_ARITHINIT`: Using unset or empty variables (dash <= 0.5.9.1 on macOS)
  or unset variables (yash <= 2.44) in arithmetic expressions causes the
  shell to exit, instead of taking them as a value of zero.
* `BUG_ARITHLNNO`: The shell supports `$LINENO`, but the variable is
   considered unset in arithmetic contexts, like `$(( LINENO > 0 ))`.
   This makes it error out under `set -u` and default to zero otherwise.
   Workaround: use shell expansion like `$(( $LINENO > 0 ))`. (FreeBSD sh)
* `BUG_ARITHSPLT`: Unquoted `$((`arithmetic expressions`))` are not
  subject to field splitting as expected. (zsh, mksh<=R49)
* `BUG_ARITHTYPE`: In zsh, arithmetic assignments (using `let`, `$(( ))`,
  etc.) on unset variables assign a numerical/arithmetic type to a variable,
  causing subsequent normal variable assignments to be interpreted as
  arithmetic expressions and fail if they are not valid as such.
* `BUG_ASGNCC01`: if `IFS` contains a `$CC01` (`^A`) character, unquoted expansions in
  shell assignments discard that character (if present). Found on: bash 4.0-4.3
* `BUG_ASGNLOCAL`: If you have a function-local variable (see `LOCALVARS`)
  with the same name as a global variable, and within the function you run a
  shell builtin command preceded by a temporary variable assignment, then
  the global variable is unset. (zsh \<= 5.7.1)
* `BUG_BRACQUOT`: shell quoting within bracket patterns has no effect (zsh < 5.3;
  ksh93) This bug means the `-` retains it special meaning of 'character
  range', and an initial `!` (and, on some shells, `^`) retains the meaning of
  negation, even in quoted strings within bracket patterns, including quoted
  variables.
* `BUG_CASELIT`: If a `case` pattern doesn't match as a pattern, it's tried
  again as a literal string, even if the pattern isn't quoted. This can
  result in false positives when a pattern doesn't match itself, like with
  bracket patterns. This contravenes POSIX and breaks use cases such as
  input validation. (AT&T ksh93) Note: modernish `match` works around this.
* `BUG_CASEPAREN`: `case` patterns without an opening parenthesis
  (i.e. with only an unbalanced closing parenthesis) are misparsed
  as a syntax error within command substitutions of the form `$( )`.
  Workaround: include the opening parenthesis. Found on: bash 3.2
* `BUG_CASESTAT`: The `case` conditional construct prematurely clobbers the
  exit status `$?`. (found in zsh \< 5.3, Busybox ash \<= 1.25.0, dash \<
  0.5.9.1)
* `BUG_CMDEXEC`: using `command exec` (to open a file descriptor, using
  `command` to avoid exiting the shell on failure) within a function causes
  bash \<= 4.0 to fail to restore the global positional parameters when
  leaving that function. It also renders bash \<=4.0 prone to hanging.
* `BUG_CMDOPTEXP`: the `command` builtin does not recognise options if they
  result from expansions. For instance, you cannot conditionally store `-p`
  in a variable like `defaultpath` and then do `command $defaultpath
  someCommand`. (found in zsh \< 5.3)
* `BUG_CMDPV`: `command -pv` does not find builtins ({pd,m}ksh), does not
  accept the -p and -v options together (zsh \< 5.3) or ignores the `-p`
  option altogether (bash 3.2); in any case, it's not usable to find commands
  in the default system PATH.
* `BUG_CMDSETPP`: using `command set --` has no effect; it does not set the
  positional parameters. For compat, use `set` without `command`. (mksh \<= R57)
* `BUG_CMDSPASGN`: preceding a
  [special builtin](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_14)
  with `command` does not stop preceding invocation-local variable
  assignments from becoming global. (AT&T ksh93)
* `BUG_CMDSPEXIT`: preceding a
  [special builtin](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_14)
  (other than `eval`, `exec`, `return` or `exit`)
  with `command` does not always stop
  it from exiting the shell if the builtin encounters error.
  (bash \<= 4.0; zsh \<= 5.2; mksh; ksh93)
* `BUG_CSNHDBKSL`: Backslashes within non-expanding here-documents within
  command substitutions are incorrectly expanded to perform newline joining,
  as opposed to left intact. (bash \<= 4.4)
* `BUG_CSUBSTDO`: If standard output (file descriptor 1) is closed before
  entering a command substitution, and any other file descriptors are
  redirected within the command substitution, commands such as `echo` or
  `putln` will not work within the command substitution, acting as if standard
  output is still closed (AT&T ksh93 \<= AJM 93u+ 2012-08-01). Workaround: see
  [`cap/BUG_CSUBSTDO.t`](https://github.com/modernish/modernish/blob/master/lib/modernish/cap/BUG_CSUBSTDO.t).
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
* `BUG_EXPORTUNS`: Setting the export flag on an otherwise unset variable
  causes a set and empty environment variable to be exported, though the
  variable continues to be considered unset within the current shell.
  (FreeBSD sh \< 13.0)
* `BUG_EVALCOBR`: `break` and `continue` do not work if they are within `eval`.
  (mksh \< R55 2017/04/12; a variant exists on FreeBSD sh \< 10.3)
* `BUG_FNSUBSH`: Function definitions within subshells (including command
  substitutions) are ignored if a function by the same name exists in the
  main shell, so the wrong function is executed. `unset -f` is also silently
  ignored. ksh93 (all current versions as of November 2018) has this bug.
  It only applies to non-forked subshells. See `NONFORKSUBSH`.
* `BUG_FORLOCAL`: a `for` loop in a function makes the iteration variable
  local to the function, so it won't survive the execution of the function.
  Found on: yash. This is intentional and documented behaviour on yash in
  non-POSIX mode, but in POSIX terms it's a bug, so we mark it as such.
* `BUG_GETOPTSMA`: The `getopts` builtin leaves a `:` instead of a `?` in
  the specified option variable if a given option that requires an argument
  lacks an argument, and the option string does not start with a `:`. (zsh)
* `BUG_HDOCBKSL`: Line continuation using *b*ac*ksl*ashes in expanding
  *h*ere-*doc*uments is handled incorrectly. (zsh up to 5.4.2)
* `BUG_HDOCMASK`: Here-documents (and here-strings, see `HERESTRING`) use
  temporary files. This fails if the current `umask` setting disallows the
  user to read, so the here-document can't read from the shell's temporary
  file. Workaround: ensure user-readable `umask` when using here-documents.
  (bash, mksh, zsh)
* `BUG_IFSCC01PP`: If `IFS` contains a `$CC01` (`^A`) control character, the
  expansion `"$@"` (even quoted) is gravely corrupted. *Since many modernish
  functions use this to loop through the positional parameters, this breaks
  the library.* (Found in bash \< 4.4)
* `BUG_IFSGLOBC`: In glob pattern matching (such as in `case` and `[[`), if a
  wildcard character is part of `IFS`, it is matched literally instead of as a
  matching character. This applies to glob characters `*`, `?`, `[` and `]`.
  *Since nearly all modernish functions use `case` for argument validation and
  other purposes, nearly every modernish function breaks on shells with this
  bug if `IFS` contains any of these three characters!*
  (Found in bash \< 4.4)
* `BUG_IFSGLOBP`: In pathname expansion (filename globbing), if a
  wildcard character is part of `IFS`, it is matched literally instead of as a
  matching character. This applies to glob characters `*`, `?`, `[` and `]`.
  (Bug found in bash, all versions up to at least 4.4)
* `BUG_IFSGLOBS`: in glob pattern matching (as in `case` or parameter
  substitution with `#` and `%`), if `IFS` starts with `?` or `*` and the
  `"$*"` parameter expansion inserts any `IFS` separator characters, those
  characters are erroneously interpreted as wildcards when quoted "$*" is
  used as the glob pattern. (AT&T ksh93)
* `BUG_IFSISSET`: AT&T ksh93 (2011/2012 versions): `${IFS+s}` always yields `s`
  even if `IFS` is unset. This applies to `IFS` only.
* `BUG_ISSETLOOP`: AT&T ksh93: Expansions like `${var+set}`
  remain static when used within a `for`, `while` or
  `until` loop; the expansions don't change along with the state of the
  variable, so they cannot be used to check whether a variable is set
  within a loop if the state of that variable may change
  in the course of the loop.
* `BUG_KUNSETIFS`: ksh93: Can't unset `IFS` under very specific
  circumstances. `unset -v IFS` is a known POSIX shell idiom to activate
  default field splitting. With this bug, the `unset` builtin silently fails
  to unset `IFS` (i.e. fails to activate field splitting) if we're executing
  an `eval` or a trap and a number of specific conditions are met. See
  [`BUG_KUNSETIFS.t`](https://github.com/modernish/modernish/blob/master/lib/modernish/cap/BUG_KUNSETIFS.t)
  for more information.
* `BUG_LNNOALIAS`: The shell has `LINENO`, but `$LINENO` is always expanded to 0
  when used within an alias. (mksh \<= R54)
* `BUG_LNNOEVAL`: The shell has `LINENO`, but `$LINENO` is always expanded to 0
  when used in `eval`. (mksh \<= R54)
* `BUG_LOOPRET1`: If a `return` command is given with a status argument within
  the set of conditional commands in a `while` or `until` loop (i.e., between
  `while`/`until` and `do`), the status argument is ignored and the function
  returns with status 0 instead of the specified status.
  Found on: dash \<= 0.5.8; zsh \<= 5.2
* `BUG_LOOPRET2`: If a `return` command is given without a status argument
  within the set of conditional commands in a `while` or `until` loop (i.e.,
  between `while`/`until` and `do`), the exit status passed down from the
  previous command is ignored and the function returns with status 0 instead.
  Found on: dash \<= 0.5.10.2; AT&T ksh93; zsh \<= 5.2
* `BUG_LOOPRET3`: If a `return` command is given within the set of conditional
  commands in a `while` or `until` loop (i.e., between `while`/`until` and
  `do`), *and* the return status (either the status argument to `return` or the
  exit status passed down from the previous command by `return` without a
  status argument) is non-zero, *and* the conditional command list itself yields
  false (for `while`) or true (for `until`), *and* the whole construct is
  executed in a dot script sourced from another script, then too many levels of
  loop are broken out of, causing **program flow corruption** or premature exit.
  Found on: zsh \<= 5.7.1
* `BUG_MULTIBIFS`: We're on a UTF-8 locale and the shell supports UTF-8
  characters in general (i.e. we don't have `WRN_MULTIBYTE`) – however, using
  multibyte characters as `IFS` field delimiters still doesn't work. For
  example, `"$*"` joins positional parameters on the first byte of `IFS`
  instead of the first character. (ksh93, mksh, FreeBSD sh, Busybox ash)
* `BUG_NOCHCLASS`: POSIX-mandated character `[:`classes`:]` within bracket
  `[`expressions`]` are not supported in glob patterns. (mksh)
* `BUG_NOEXPRO`: Cannot export read-only variables. (zsh <= 5.7.1 in sh mode)
* `BUG_NOUNSETEX`: Cannot assign export attribute to variables in an unset
  state; exporting a variable immediately sets it to the empty value.
  However, the empty variable is still not actually exported until assigned
  to, declared `readonly`, or otherwise modified.
  (zsh \< 5.3)
* `BUG_OPTNOLOG`: on dash, setting `-o nolog` causes `$-` to wreak havoc:
  trying to expand `$-` silently aborts parsing of an entire argument,
  so e.g. `"one,$-,two"` yields `"one,"`. (Same applies to `-o debug`.)
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
  with `"$emptyvariable"$@`, not `$@"$emptyvariable"`.
  (mksh \<= R50f; FreeBSD sh \<= 10.3)
* `BUG_PP_03`: When `IFS` is unset or empty (zsh 5.3.x) or empty (mksh \<= R50),
  assigning `var=$*` only assigns the first field, failing to join and
  discarding the rest of the fields. Workaround: `var="$*"`
  (POSIX leaves `var=$@`, etc. undefined, so we don't test for those.)
* `BUG_PP_03A`: When `IFS` is unset, assignments like `var=$*`
  incorrectly remove leading and trailing spaces (but not tabs or
  newlines) from the result. Workaround: quote the expansion. Found on:
  bash 4.3 and 4.4.
* `BUG_PP_03B`: When `IFS` is unset, assignments like `var=${var+$*}`,
  etc. incorrectly remove leading and trailing spaces (but not tabs or
  newlines) from the result. Workaround: quote the expansion. Found on:
  bash 4.3 and 4.4.
* `BUG_PP_03C`: When `IFS` is unset, assigning `var=${var-$*}` only assigns
  the first field, failing to join and discarding the rest of the fields.
  (zsh 5.3, 5.3.1) Workaround: `var=${var-"$*"}`
* `BUG_PP_04`: If `IFS` is set and empty, assigning the positional parameters
  to a variable using a conditional assignment within a parameter substitution,
  such as `: ${var=$*}`, discards everything but the last field from the
  assigned value while incorrectly generating multiple fields for the
  expansion. (mksh \<= R54)
* `BUG_PP_04A`: Like BUG_PP_03A, but for conditional assignments within
  parameter substitutions, as in `: ${var=$*}` or `: ${var:=$*}`.
  Workaround: quote either `$*` within the expansion or the expansion
  itself. (bash \<= 4.4)
* `BUG_PP_04E`: When assigning the positional parameters ($*) to a variable
  using a conditional assignment within a parameter substitution, e.g.
  `: ${var:=$*}`, the fields are always joined and separated by spaces,
  except if `IFS` is set and empty. Workaround as in BUG_PP_04A.
  (bash 4.3)
* `BUG_PP_04_S`: When `IFS` is null (empty), the result of a substitution
  like `${var=$*}` is incorrectly field-split on spaces. The difference
  with BUG_PP_04 is that the assignment itself succeeds normally.
  Found on: bash 4.2, 4.3
* `BUG_PP_05`: [POSIX says](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_05_02)
  that empty `$@` and `$*` generate zero fields, but with null `IFS`, empty
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
  (even though, as said, `IFS` does not contain a space).
  Found on: bash 4.3
* `BUG_PP_10`: When `IFS` is null (empty), assigning `var=$*` removes any
  `$CC01` (^A) and `$CC7F` (DEL) characters. (bash 3, 4)
* `BUG_PP_10A`: When `IFS` is non-empty, assigning `var=$*` prefixes each
  `$CC01` (^A) and `$CC7F` (DEL) character with a `$CC01` character. (bash 4.4)
* `BUG_PP_1ARG`: When `IFS` is empty on bash <= 4.3 (i.e. field
  splitting is off), `${1+"$@"}` or `"${1+$@}"` is counted as a single
  argument instead of each positional parameter as separate arguments.
  This also applies to prepending text only if there are positional
  parameters with something like `"${1+foobar $@}"`.
* `BUG_PP_MDIGIT`: Multiple-digit positional parameters don't require expansion
  braces, so e.g. `$10` = `${10}` (dash; Busybox ash). This is classed as a bug
  because it causes a straight-up incompatibility with POSIX scripts. POSIX
  [says](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_06_02):
  "The parameter name or symbol can be enclosed in braces, which are
  optional except for positional parameters with more than one digit [...]".
* `BUG_PSUBASNCC`: in an assignment parameter substitution of the form
  `${foo=value}`, if the characters `$CC01` (^A) or `$CC7F` (DEL) are in the
  value, all their occurrences are stripped from the expansion (although the
  assignment itself is done correctly). If the expansion is quoted, only
  `$CC01` is stripped. This bug is independent of the state of `IFS`, except if
  `IFS` is null, the assignment in `${foo=$*}` (unquoted) is buggy too: it
  strips `$CC01` from the assigned value. (Found on bash 4.2, 4.3, 4.4)
* `BUG_PSUBBKSL1`: A backslash-escaped `}` character within a quoted parameter
  substitution is not unescaped. (bash 3.2, dash \<= 0.5.9.1, Busybox 1.27 ash)
* `BUG_PSUBEMIFS`: if `IFS` is empty (no split, as in safe mode), then if a
  parameter substitution of the forms `${foo-$*}`, `${foo+$*}`, `${foo:-$*}` or
  `${foo:+$*}` occurs in a command argument, the characters `$CC01` (^A) or
  `$CC7F` (DEL) are stripped from the expanded argument. (Found on: bash 4.4)
* `BUG_PSUBEMPT`: Expansions of the form `${V-}` and `${V:-}` are not
  subject to normal shell empty removal if that parameter is unset, causing
  unexpected empty arguments to commands. Workaround: `${V+$V}` and
  `${V:+$V}` work as expected. (Found on FreeBSD 10.3 sh)
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
  but with this bug yields `foobar`. (dash \<= 0.5.9.1; Busybox 1.27 ash)
* `BUG_PSUBSQHD`: Like BUG_PSUBSQUOT, but included a here-document instead of
  quoted with double quotes. (dash \<= 0.5.9.1; mksh)
* `BUG_PUTIOERR`: Shell builtins that output strings (`echo`, `printf`, ksh/zsh
  `print`), and thus also modernish `put` and `putln`, do not check for I/O
  errors on output. This means a script cannot check for them, and a script
  process in a pipe can get stuck in an infinite loop if `SIGPIPE` is ignored.
* `BUG_READWHSP`: If there is more than one field to read, `read` does not
   trim trailing `IFS` whitespace. (dash 0.5.7, 0.5.8)
* `BUG_REDIRIO`: the I/O redirection operator `<>` (open a file descriptor
  for both read and write) defaults to opening standard output (i.e. is
  short for `1<>`) instead of defaulting to opening standard input (`0<>`) as
  [POSIX specifies](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_07_07).
  (AT&T ksh93)
* `BUG_REDIRPOS`: Buggy behaviour occurs if a *redir*ection is *pos*itioned
  in between to variable assignments in the same command. On zsh 5.0.x, a
  parse error is thrown. On zsh 5.1 to 5.4.2, anything following the
  redirection (other assignments or command arguments) is silently ignored.
* `BUG_SCLOSEDFD`: bash \< 5.0 and dash fail to establish a block-local scope
  for a file descriptor that is added to the end of the block as a redirection
  that closes that file descriptor (e.g. `} 8<&-` or `done 7>&-`). If that FD
  is already closed outside the block, the FD remains global, so you can't
  locally `exec` it. So with this bug, it is not straightforward to make a
  block-local FD appear initially closed within a block. Workaround: first open
  the FD, then close it – for example: `done 7>/dev/null 7>&-` will establish
  a local scope for FD 7 for the preceding `do`...`done` block while still
  making FD 7 appear initially closed within the block.
* `BUG_SELECTEOF`: in a shell-native `select` loop, the `REPLY` variable
  is not cleared if the user presses Ctrl-D to exit the loop. (zsh \<= 5.2)
* `BUG_SETOUTVAR`: The `set` builtin (with no arguments) only prints native
  function-local variables when called from a shell function. (yash \<= 2.46)
* `BUG_SPCBILOC`: Variable assignments preceding
  [special builtins](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_14)
  create a partially function-local variable if a variable by the same name
  already exists in the global scope. (bash \< 5.0 in POSIX mode)
* `BUG_TESTERR1A`: `test`/`[` exits with a non-error `false` status
  (1) if an invalid argument is given to an operator. (AT&T ksh93)
* `BUG_TESTERR1B`: `test`/`[` exits with status 1 (false) if there are too few
  or too many arguments, instead of a status > 1 as it should do. (zsh \<= 5.2)
* `BUG_TESTILNUM`: On dash (up to 0.5.8), giving an illegal number to `test -t`
  or `[ -t` causes some kind of corruption so the next `test`/`[` invocation
  fails with an "unexpected operator" error even if it's legit.
* `BUG_TESTONEG`: The `test`/`[` builtin supports a `-o` unary operator to
  check if a shell option is set, but it ignores the `no` prefix on shell
  option names, so something like `[ -o noclobber ]` gives a false positive.
  Bug found on yash up to 2.43. (The `TESTO` feature test implicitly checks
  against this bug and won't detect the feature if the bug is found.)
* `BUG_TESTRMPAR`: zsh: in binary operators with `test`/`[`, if the first
  argument starts with `(` and the last with `)`, both the first and the
  last argument are completely removed, leaving only the operator, and the
  result of the operation is incorrectly true because the operator is
  incorrectly parsed as a non-empty string. This applies to any operator.
* `BUG_TRAPEMPT`: The `trap` builtin does not quote empty traps in its
  output, rendering the output unsuitable for shell re-input. For instance,
  `trap '' INT; trap` outputs "`trap --  INT`" instead of "`trap -- '' INT`".
  (found in mksh \<= R56c)
* `BUG_TRAPEXIT`: the shell's `trap` builtin does not know the EXIT trap by
  name, but only by number (0). Using the name throws a "bad trap" error. Found in
  [klibc 2.0.4 dash](https://git.kernel.org/pub/scm/libs/klibc/klibc.git/tree/usr/dash).
* `BUG_TRAPRETIR`: Using `return` within `eval` triggers infinite recursion if
  both a RETURN trap and the `functrace` shell option are active. This bug in
  bash-only functionality triggers a crash when using modernish, so to avoid
  this, modernish automatically disables the `functrace` shell option if a
  `RETURN` trap is set or pushed and this bug is detected. (bash 4.3, 4.4)
* `BUG_TRAPSUB0`: Subshells in traps fail to pass down a nonzero exit status of
  the last command they execute, under certain conditions or consistently,
  depending on the shell. (bash \<= 4.0; dash 0.5.9 - 0.5.10.2; yash \<= 2.47)
* `BUG_UNSETUNXP`: If an unset variable is given the export flag using the
  `export` command, a subsequent `unset` command does not remove that export
  flag again. Workaround: assign to the variable first, then unset it to
  unexport it. (Found on AT&T ksh JM-93u-2011-02-08; Busybox 1.27.0 ash)

### Warning IDs ###

Warning IDs do not identify any characteristic of the shell, but instead
warn about a potentially problematic system condition that was detected at
initialisation time.

* `WRN_EREMBYTE`: The current system locale setting supports Unicode UTF-8
  multi-byte/variable-length characters, but the utility used by
  [`str ematch`](#user-content-string-tests)
  to match extended regular expressions (EREs) does not support them
  and treats all characters as single bytes. This means multibyte characters
  will be matched as multiple characters, and character `[:`classes`:]`
  within bracket expressions will only match ASCII characters.
* `WRN_MULTIBYTE`: The current system locale setting supports Unicode UTF-8
  multi-byte/variable-length characters, but the current shell does not
  support them and treats all characters as single bytes. This means
  counting or processing multi-byte characters with the current shell will
  produce incorrect results. Scripts that need compatibility with this
  system condition should check `if thisshellhas WRN_MULTIBYTE` and resort
  to a workaround that uses external utilities where necessary.
* `WRN_NOSIGPIPE`: Modernish has detected that the process that launched
  the current program has set `SIGPIPE` to ignore, an irreversible condition
  that is in turn inherited by any process started by the current shell, and
  their subprocesses, and so on. The system constant
  [`$SIGPIPESTATUS`](#user-content-modernish-system-constants)
  is set to the special value 99999 and neither the current shell nor any
  process it spawns is now capable of receiving `SIGPIPE`. The
  [`-P` option to `harden`](#hardening-while-allowing-for-broken-pipes)
  is also rendered ineffective.
  Depending on how a given command `foo` is implemented, it is now possible
  that a pipeline such as `foo | head -n 10` never ends; if `foo` doesn't
  check for I/O errors, the only way it would ever stop trying to write
  lines is by receiving `SIGPIPE` as `head` terminates.
  Programs that use commands in this fashion should check `if thisshellhas
  WRN_NOSIGPIPE` and either employ workarounds or refuse to run if so.


## Appendix B: Regression test suite ##

Modernish comes with a suite of regression tests to detect bugs in modernish
itself, which can be run using `modernish --test` after installation. By
default, it will run all the tests verbosely but without tracing the command
execution. The `install.sh` installer will run `modernish --test -eqq` on the
selected shell before installation.

A few options are available to specify after `--test`:

* `-e`: disable or reduce expensive (i.e. slow or memory-hogging) tests.
* `-q`: quieter operation; report expected fails [known shell bugs]
  and unexpected fails [bugs in modernish]). Add `-q` again for
  quietest operation (report unexpected fails only).
* `-s`: entirely silent operation.
* `-t`: run only specific test sets or tests. Test sets are those listed
  in the full default output of `modernish --test`. This option requires
  an option-argument in the following format:    
  *testset1*`:`*num1*`,`*num2*`,`…`/`*testset2*`:`*num1*`,`*num2*`,`…`/`…    
  The colon followed by numbers is optional; if omitted, the entire set
  will be run, otherwise the given numbered tests will be run in the given
  order. Example: `modernish --test -t match:2,4,7/arith/shellquote:1` runs
  test 2, 4 and 7 from the `match` set, the entire `arith` set, and only
  test 1 from the `shellquote` set.
  A *testset* can also be given as a shell glob pattern, in which case
  the set(s) matching the pattern will be run.
* `-x`: trace each test using the shell's `xtrace` facility. Each trace is
  stored in a separate file in a specially created temporary directory. By
  default, the trace is deleted if a test does not produce an unexpected
  fail. Add `-x` again to keep expected fails as well, and again to
  keep all traces regardless of result. If any traces were saved,
  modernish will tell you the location of the temporary directory at the
  end, otherwise it will silently remove the directory again.

These short options can be combined so, for example,
`--test -qxx` is the same as `--test -q -x -x`.

### Difference between capability detection and regression tests ###

Note the difference between these regression tests and the cap tests listed in
[Appendix A](#user-content-appendix-a-list-of-shell-cap-ids). The latter are
tests for whatever shell is executing modernish: they detect capabilities
(features, quirks, bugs) of the current shell. They are meant to be run via
[`thisshellhas`](#user-content-shell-capability-detection) and are designed to
be taken advantage of in scripts. On the other hand, these tests run by
`modernish --test` are regression tests for modernish itself. It does not
make sense to use these in a script.

New/unknown shell bugs can still cause modernish regression tests to fail,
of course. That's why some of the regression tests also check for
consistency with the results of the capability detection tests: if there is a
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

(adding any further options you like – for instance, you might like to add
`-q` to avoid very long terminal output). On first run, `testshells` will
generate a list of shells it can find on your system and it will give you a
chance to edit it before proceeding.


## Appendix C: Supported locales ##

modernish, like most shells, fully supports two system locales: POSIX
(a.k.a. C, a.k.a. ASCII) and Unicode's UTF-8. It will work in other locales,
but things like converting to upper/lower case, and matching single
characters in patterns, are not guaranteed.

*Caveat:* some shells or operating systems have bugs that prevent (or lack
features required for) full locale support. If portability is a concern,
check for `thisshellhas WRN_MULTIBYTE` or `thisshellhas BUG_NOCHCLASS`
where needed. See [Appendix A](#user-content-appendix-a-list-of-shell-cap-ids).

Scripts/programs should *not* change the locale (`LC_*` or `LANG`) after
initialising modernish. Doing this might break various functions, as
modernish sets specific versions depending on your OS, shell and locale.
(Temporarily changing the locale is fine as long as you don't use
modernish features that depend on it – for example, setting a specific
locale just for an external command. However, if you use `harden`, see
the [important note](#user-content-important-note-on-variable-assignments)
in its documentation!)


## Appendix D: Supported shells ##

Modernish builds on the
[POSIX 2018 Edition](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/contents.html)
standard, so it should run on any sufficiently POSIX-compliant shell and
operating system. It uses both
[bug/feature detection](#user-content-shell-capability-detection)
and
[regression testing](#user-content-appendix-b-regression-test-suite)
to determine whether it can run on any particular shell, so it does not
block or support particular shell versions as such. However, modernish has
been confirmed to run correctly on the following shells:

-   [bash](https://www.gnu.org/software/bash/) 3.2 or higher
-   [Busybox](https://busybox.net/) ash 1.20.0 or higher, excluding 1.28.x
    (also possibly excluding anything older than 1.27.x on UTF-8 locales,
    depending on your operating system)
-   [dash](http://gondor.apana.org.au/~herbert/dash/) (Debian sh)
    0.5.7 or higher, excluding 0.5.10 and 0.5.10.1
-   [FreeBSD](https://www.freebsd.org/) sh 10.0 or higher
-   [gwsh](https://github.com/hvdijk/gwsh)
-   [ksh](http://www.kornshell.com/) AJM 93u+ 2012-08-01
-   [mksh](http://www.mirbsd.org/mksh.htm) version R52 or higher
-   [yash](http://yash.osdn.jp/) 2.40 or higher (2.44+ for POSIX mode)
-   [zsh](http://www.zsh.org/) 5.0.8 or higher for portable scripts;
    zsh 5.3 or higher for correct integration with native zsh scripts
    using `emulate -R sh -c '. modernish'`

Currently known *not* to run modernish due to excessive bugs:

-   bosh ([Schily](http://schilytools.sourceforge.net/) Bourne shell)
-   [NetBSD](https://www.netbsd.org/) sh (fix expected in NetBSD 9)
-   pdksh, including [NetBSD](https://www.netbsd.org/) ksh and
    [OpenBSD](https://www.openbsd.org/) ksh


## Appendix E: zsh: integration with native scripts ##

This appendix is specific to [zsh](http://zsh.sourceforge.net/).

While modernish duplicates some functionality already available natively
on zsh, it still has plenty to add. However, writing a normal
[simple-form](#user-content-simple-form) modernish script turns
`emulate sh` on for the entire script, so you lose important aspects
of the zsh language.

But there is another way – modernish functionality may be integrated
with native zsh scripts using 'sticky emulation', as follows:

```sh
emulate -R sh -c '. modernish'
```

This causes modernish functions to run in sh mode while your script will still
run in native zsh mode with all its advantages. The following notes apply:

* Using the [safe mode](#user-content-use-safe) is *not* recommended, as zsh
  does not apply split/glob to variable expansions by default, and the
  modernish safe mode would defeat the `${~var}` and `${=var}` flags that apply
  these on a case by case basis. This does mean that:
    * The `--split` and `--glob` operators to constructs such as
      [`LOOP find`](#user-content-the-find-loop)
      are not available. Use zsh expansion flags instead.
    * Quoting literal glob patterns to commands like `find` remains necessary.
* Using [`LOCAL`](#user-content-use-varlocal) is not recommended.
  [Anonymous functions](http://zsh.sourceforge.net/Doc/Release/Functions.html#Anonymous-Functions)
  are the native zsh equivalent.
* Native zsh loops should be preferred over modernish loops, except where
  modernish adds functionality not available in zsh (such as `LOOP find` or
  [user-programmed loops](#user-content-creating-your-own-loop)).
* The [trap stack](#user-content-use-varstacktrap)
  requires zsh 5.3 or later to function correctly with sticky emulation.
  (Since there is no way for modernish to determine whether it is being
  initialised in sticky emulation mode, the module cannot refuse to
  load if this requirement is not met.)

See `man zshbuiltins` under `emulate`, option `-c`, for more information.

---

`EOF`
