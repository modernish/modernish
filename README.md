# modernish: a shell modernizer library #

modernish is an ambitious, as-yet experimental, cross-platform POSIX shell
feature detection and language extension library. It aims to extend the
shell language with extensive feature testing and language enhancements,
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
at solving specific and commonly experiened deficits and annoyances of the
shell language, and not at adding/faking things that are foreign to it, such
as object orientation or functional programming. (However, since modernish
is modular, nothing stops anyone from adding a module attempting to
implement these things.)

The library builds on pure POSIX 2013 Edition (including full C-style shell
arithmetics with assignment, comparison and conditional expressions), so it
should run on any POSIX-compliant shell and operating system. But it does
not shy away from using non-standard extensions where available to enhance
performance or robustness.

Some example programs are in `share/doc/modernish/examples` and test
programs are in `share/doc/modernish/testsuite`.


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
  where needed. See Appendix A under [Bugs](#bugs).
* Scripts/programs should *not* change the locale (`LC_*` or `LANG`) after
  initialising modernish. Doing this might break various functions, as
  modernish sets specific versions depending on your OS, shell and locale.
  (Temporarily changing the locale is fine as long as you don't use
  modernish features that depend on it -- for example, setting a specific
  locale just for an external command. However, if you use `harden()`, see
  the [important note](#important-note-on-variable-assignments) in its
  documentation below!)

## Interactive use ##

Modernish is primarily designed to enhance shell programs/scripts, but also
offers features for use in interactive shells. For instance, the new `with`
loop construct from the `loop/with` module can be quite practical to repeat
an action x times, and the `safe` module on interactive shells provides
convenience functions for manipulating, saving and restoring the state of
field splitting and globbing.

To use modernish on your favourite interactive shell, you have to add it to
your `.profile`, `.bashrc` or similar init file.

**Important:** Modernish removes all aliases upon initialising, but it does
depend on other settings, such as the locale. So you have to organise your
`.profile` or similar file in the following order:

* *first*, do everything except aliases and modernish (`PATH`, locale, etc.);
* *then*, `. modernish` and `use` any modules you want;
* *then* define any additional `alias`es you want.

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


## Shell feature testing ##

Modernish includes a battery of shell bug, quirk and feature tests, each of
which is given a special ID. These are easy to query using the `thisshellhas`
function, e.g. `if thisshellhas LOCAL, then` ... That same function also tests
if 'thisshellhas' a particular reserved word or builtin command.

To reduce start up time, the main bin/modernish script only includes the
bug/quirk/feature tests that are essential to the functioning of it; these are
considered built-in tests. The rest, considered external tests, are included as
small test scripts in libexec/modernish/cap/*.t which are sourced on demand.

Feature testing is used by library functions to conveniently work around bugs or
take advantage of special features not all shells have. For instance,
`ematch` will use `[[` *var* `=~` *regex* `]]` if available and fall back to
`grep -E` otherwise. But the use of feature testing is not restricted to
modernish itself; any script using the library can do this in the same way.

The `thisshellhas` function is an essential component of feature testing in
modernish. There is no standard way of testing for the presence of a shell
built-in or reserved word, so different shells need different methods; the
library tests for this and loads the correct version of this function.

See Appendix A below for a list of capabilities and bugs currently tested for.


## Modernish system constants ##

Modernish provides certain constants (read-only variables) to make life easier.
These include:

* `$MSH_VERSION`: The version of modernish.
* `$MSH_PREFIX`: Installation prefix for this modernish installation (e.g.
  /usr/local).
* `$ME`: Path to the current program. Replacement for `$0`. This is
  necessary if the hashbang path `#!/usr/bin/env modernish` is used, or if
  the program is launched like `sh /path/to/bin/modernish
  /path/to/script.sh', as these set `$0` to the path to bin/modernish and
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

* `$CONTROLCHARS`: All the control characters.
* `$WHITESPACE`: All whitespace characters.
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


## Enhanced exit and emergency halt ##

`die`: reliably halt program execution, even from subshells, optionally
printing an error message.

`exit`: extended usage: `exit` [ `-u` ] [ *<status>* [ *<message>* ] ]
If the -u option is given, the function showusage() is called, which has
a simple default but can be redefined by the script.

### Supporting shell utilities ###

`insubshell`: easily check if you're currently running in a subshell.
(Note: on AT&T ksh93, beware of BUG_KSHSUBVAR; see Appendix A)

`setstatus`: manually set the exit status `$?` to the desired value. The
function exits with the status indicated. This is useful in conditional
constructs if you want to prepare a particular exit status for a subsequent
'exit' or 'return' command to inherit under certain circumstances.


## Feature testing ##

`thisshellhas`: test if a keyword is a shell built-in command or shell
keyword/reserved word, or the ID of a modernish capability/bug that this
shell has.

Note that a modernish capability/bug ID is distinguished from a shell
keyword or command by the fact that the former is written in only ASCII
capital letters A to Z and the underscore character. Alternatively, the
`--rw=`/`--kw=` option specifically checks for a reserved word and the
`--bi=` option specifically checks for a built-in command.

The function can also run all the external modernish bug/feature tests that
haven't already been run and cache the results (`--cache`) and output the
modernish IDs of the positive tests, one per line (`--show`).


## Working with variables ##

`isvarname`: Test if argument is valid portable variable (or shell
function) name.

`isset`: check if a variable is set.

`unexport`: the opposite of `export`. Unexport a variable while preserving
its value, or (while working under `set -a`) don't export it at all.


## Quoting strings for subsequent parsing by the shell ##

`shellquote`: fast and reliable shell-quoting function that uses an
optimized algorithm. This is essential for the safe use of `eval` or
any other contexts where the shell must parse untrusted input.

`shellquoteparams`: shell-quote the current shell's positional parameters
in-place.

`storeparams`: store the positional parameters, or a sub-range of them,
in a variable, in a shellquoted form suitable for restoration using
`eval "set -- $varname"`. For instance: `storeparams -f2 -t6 VAR`
quotes and stores `$2` to `$6` in `VAR`.


## The stack ##

`push` & `pop`: every variable and shell option gets its own stack. For
variables, both the value and the set/unset state is (re)stored. Other
stack functions: `stackempty` (test if a stack is empty); `stacksize`
(output number of items on a stack); `printstack` (output the stack's
content); `clearstack` (clear a stack).

`pushparams` and `popparams`: push and pop the complete set of positional
parameters.

### The trap stack ###

`pushtrap` and `poptrap`: traps are now also stack-based, so that each
program component or library module can set its own trap commands
without interfering with others.

`pushtrap` works like regular `trap`, with a few exceptions:

* Adds traps for a signal without overwriting previous ones.
* Unlike regular traps, a stack-based trap does not cause a signal to be
  ignored. Setting one will cause it to be executed upon the shell receiving
  that signal, but after the stack traps complete execution, modernish re-sends
  the signal to the main shell, causing it to behave as if no trap were set
  (unless a regular POSIX trap is also active).
* Each stack trap is executed in a new subshell to keep it from interfering
  with others. This means a stack trap cannot change variables except within
  its own environment, and 'exit' will only exit the trap and not the program.

`poptrap` takes just a signal name as an argument. It takes the last-pushed
trap for a signal off the stack, storing the command that was set for that
signal into the REPLY variable, in a format suitable for re-entry into the
shell.

#### Trap stack compatibility considerations ####

Modernish tries hard to avoid incompatibilities with existing trap practice.
To that end, it intercepts the regular POSIX 'trap' command using an alias,
reimplementing and interfacing it with the shell's builtin trap facility
so that plain old regular traps play nicely with the trap stack. You should
not notice any changes in the POSIX 'trap' command's behaviour, except for
the following:

* The regular 'trap' command does not overwrite stack traps (but does
  overwrite previous regular traps).
* The 'trap' command with no arguments, which prints the traps that are set
  in a format suitable for re-entry into the shell, now also prints the
  stack traps as 'pushtrap' commands. (`bash` users might notice the `SIG`
  prefix is not included in the signal names written.)
* When setting traps, signal name arguments may now have the `SIG` prefix on
  all shells; that prefix is quietly accepted and discarded.
* Saving the traps to a variable using command substitution (as in:
  `var=$(trap)`) now works on every shell supported by modernish, including
  (d)ash, mksh and zsh.
* Any traps set prior to initialising modernish (or by bypassing the
  modernish 'trap' alias to access the system command directly) will work as
  normal, but *will be overwritten* by a `pushtrap` for the same signal. To
  remedy this, you can issue a simple `trap` command; as modernish prints
  the traps, it will detect ones it doesn't yet know about and make them
  work nicely with the trap stack.

POSIX traps for each signal are always executed after that signal's stack-based
traps; this means they should not rely on modernish modules that use the trap
stack to clean up after themselves on exit, as those cleanups would already
have been done.


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

`harden` [ `-p` ] [ `-t` ] [ `as` *funcname* ] *command_name_or_path* [ *testexpr* ]

The status test expression \<testexpr\> is like a shell arithmetic
expression, with the binary operators `==` `!=` `<=` `>=` `<` `>` turned
into unary operators referring to the exit status of the command in
question. Assignment operators are disallowed. Everything else is the same,
including `&&` (logical and) and `||` (logical or) and parentheses.

Examples:

    harden make                           # simple check for status > 0
    harden as tar '/usr/local/bin/gnutar' # id.; be sure to use this 'tar' version
    harden grep '> 1'                     # for grep, status > 1 means error
    harden gzip '==1 || >2'               # 1 and >2 are errors, but 2 isn't (see manual)

### Important note on variable assignments ###

As far as the shell is concerned, hardened commands are shell functions and
not external or builtin commands. This essentially changes one behaviour of
the shell: variable assignments preceding the command will not be local to
the command as usual, but *will persist* after the command completes.
(POSIX technically makes that behaviour
[optional](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_09_01)
but all current shells behave the same in POSIX mode.)

For example, this means that something like

    harden grep '>1'
    # [...]
    LC_ALL=C grep regex some_ascii_file.txt

should never be done, because the meant-to-be-temporary `LC_ALL` locale
assignment will persist and is likely to cause problems further on.

Fortunately, `harden` works even from subshells, so if performance is not
absolutely critical, there's a convenient workaround in forking a subshell:

    (export LC_ALL=C; grep regex some_ascii_file.txt)

### Important note on hardening `rm` ###

*Don't use the `-f` flag with hardened `rm`* (actually, don't use it at all
in your programs, full stop). The `-f` flag will cause `rm` to ignore all
errors and continue trying to delete things. Too many home directories and
entire systems have been deleted because someone did `rm -rf` with
[unvalidated parameters resulting from broken algorithms](http://www.techrepublic.com/article/moving-steams-local-folder-deletes-all-user-files-on-linux/)
or even just because of a
[simple typo](https://github.com/MrMEEE/bumblebee-Old-and-abbandoned/issues/123).
Not using `-f` would cause `rm` to fail properly in many cases, allowing
`harden` to do its thing to protect you and your users.

### Hardening while allowing for broken pipes ###

If you're piping a command's output into another command that may close
the pipe before the first command is finished, you can use the `-p` option
to allow for this:

    harden -p gzip '==1 || >2'          # also tolerate gzip being killed by SIGPIPE
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

    harden as hardGrep grep '> 1'	# hardGrep does not tolerate being aborted
    harden as pipeGrep -p grep '> 1'	# pipeGrep for use in pipes that may break

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


## Outputting strings ##

`print`: prints each argument on a separate line (unlike `echo` which
prints all arguments on one line). There is no processing of options or
escape codes. Note: this is completely different from ksh/zsh `print`.
(On shells with printf built in, `print` is simply an alias for `printf
'%s\n'`.)

`echo`: a modernish version of `echo`, so at least all modernish programs
can safely expect the same behaviour. This version does not interpret
any control characters and supports only one option, `-n`, which, like
BSD `echo`, suppresses the newline. However, unlike BSD `echo`, if `-n`
is the only argument, it is not interpreted as an option and the string
`-n` is printed instead. This makes it safe to output arbitrary data
using this version of `echo` as long as it is given as a single argument
(using quoting if needed).


## Enhanced dot scripts ##

`source`: bash/zsh-style `source` command now available to all POSIX
shells, complete with optional positional parameters given as extra
arguments (which is not supported by POSIX `.`).


## Testing numbers, strings and files ##

Complete replacement for `test`/`[` in the form of speed-optimized shell
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

`isint`: test if a given argument is a decimal, octal or hexadecimcal integer
number in valid POSIX shell syntax, ignoring leading (but not trailing) spaces
and tabs.

### String tests ###
    empty:        test if string is empty
    identic:      test if 2 strings are identical
    sortsbefore:  test if string 1 sorts before string 2
    sortsafter:   test if string 1 sorts after string 2
    contains:     test if string 1 contains string 2
    startswith:   test if string 1 starts with string 2
    endswith:     test if string 1 ends with string 2
    match:        test if string matches a glob pattern
    ematch:       test if string matches an extended regex

### File type tests ###
These avoid the snags with symlinks you get with `[` and `[[`.

    is present:    test if file exists (yields true even if invalid symlink)
    is -L present: test if file exists and is not an invalid symlink
    is nonempty:   test is file exists, is not an invalid symlink, and is
                   not empty (also works for dirs with read permission)
    is setuid:     test if file has user ID bit set
    is setgid:     test if file has group ID bit set
    is sym:        test if file is symlink
    is -L sym:     test if file is a valid symlink
    is reg:        test if file is a regular file
    is -L reg:     test if file is regular or a symlink pointing to a regular
    is dir:        test if file is a directory
    is -L dir:     test if file is dir or symlink pointing to dir
    is fifo, is -L fifo, is socket, is -L socket, is blockspecial,
                   is -L blockspecial, is charspecial, is -L charspecial:
                   same pattern, you figure it out :)
    is onterminal: test if file descriptor is associated with a terminal

### File permission tests ###
These use a more straightforward logic than `[` and `[[`.

    can read:      test if we have read permission for a file
    can write:     test if we have write permission for a file or directory
                   (for directories, only true if traverse permission as well)
    can exec:      test if we have execute permission for a file (not a dir)
    can traverse:  test if we can enter (traverse through) a directory


## Basic string operations ##
The main modernish library contains functions for a few basic string
manipulation operations (because they are needed by other functions in the main
library). Currently these are:

    toupper:       convert the contents of a variable to upper case letters
    tolower:       convert the contents of a variable to lower case letters
                   (note: the argument for these is a variable name without `$`)

`toupper` and `tolower` try hard to use the fastest available method on the
particular shell your program is running on. They use built-in shell
functionality where available and working correctly, otherwise they fall back
on running the external `tr` command.


## Modules ##

`use`: use a modernish module. It implements a simple Perl-like module
system with names such as 'safe', 'var/setlocal' and 'loop/select'.
These correspond to files 'safe.mm', 'var/setlocal.mm', etc. which are
dot scripts defining functionality. Any extra arguments to the `use`
command are passed on to the dot script unmodified, so modules can
implement option parsing to influence their initialization.

### use safe ###
Does `IFS=''; set -f -u -C`, that is: field splitting and globbing are
disabled, variables must be defined before use, and 

Essentially, this is a whole new way of shell programming,
eliminating most variable quoting headaches, protects against typos
in variable names wreaking havoc, and protects files from being
accidentally overwritten by output redirection.

Of course, you don't get field splitting and globbing. But modernish
provides various ways of enabling one or both only for the commands
that need them, `setlocal`...`endlocal` blocks chief among them
(see `use var/setlocal` below).

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

#### Arithmetic comparison shortcuts ####

These have the same name as their `test`/`[` option equivalents. Unlike
with `test`, the arguments are shell integer arith expressions, which can be
anything from simple numbers to complex expressions. As with `$(( ))`,
variable names are expanded to their values even without the `$`.

    Function:         Returns succcessfully if:
    eq <expr> <expr>  the two expressions evaluate to the same number
    ne <expr> <expr>  the two expressions evaluate to different numbers
    lt <expr> <expr>  the 1st expr evaluates to a smaller number than the 2nd
    le <expr> <expr>  the 1st expr eval's to smaller than or equal to the 2nd
    gt <expr> <expr>  the 1st expr evaluates to a greater number than the 2nd
    ge <expr> <expr>  the 1st expr eval's to greater than or equal to the 2nd

### use var/array ###
Associative arrays using the `array` function. (Not finished yet.)

### use var/setlocal ###
Defines a new `setlocal`...`endlocal` shell code block construct with
arbitrary local variables, local field splitting and globbing settings,
and arbitrary local shell options. Internally, these blocks are shell
functions that are executed immediately upon defining them, then discarded.

zsh programmers may recognise this as pretty much the equivalent of
anonymous functions. In fact, on zsh, `setlocal` blocks take advantage of
that functionality.

### use var/string ###
String manipulation functions.

`trim`: strip whitespace (or other characters) from the beginning and end of
a variable's value.

`replacein`: Replace leading, `-t`railing or `-a`ll occurrences of a string by
another string in a variable.

`append` and `prepend`: Append or prepend zero or more strings to a
variable, separated by a string of zero or more characters, avoiding the
hairy problem of dangling separators. Optionally shell-quote each string
before appending or prepending.

### use sys/base ###
Some very common external commands ought to be standardised, but aren't. For
instance, the `which` and `readlink` commands have incompatible options on
various GNU and BSD variants and may be absent on other Unix-like systems.
This module provides a complete re-implementation of such basic utilities
written as modernish shell functions. Scripts that use the modernish version
of these utilities can expect to be fully cross-platform. They also have
various enhancements over the GNU and BSD originals.

`readlink`: Read the target of a symbolic link. Robustly handles weird
filenames such as those containing newline characters. Stores result in the
$REPLY variable and optionally writes it on standard output. Optionally
canonicalises each path, following all symlinks encountered (for this mode,
all but the last component must exist). Optionally shell-quote each item of
output for later parsing by the shell, separating multiple items with spaces
instead of newlines.

`which`: Outputs either the first path of each given command, or all
available paths, according to the system $PATH.  Stores result in the $REPLY
variable and optionally writes it on standard output. Optionally shell-quote
each item of output for later parsing by the shell, separating multiple
items with spaces instead of newlines. If given the -P option with a
non-negative integer number, strips that many path elements from the output
starting from the right; this is useful to determine a package's install
prefix. For instance, `which -P2 zsh` tells you the install prefix of `zsh`
by stripping the command name and /bin/ from the path.

### use sys/dir ###
Functions for working with directories. So far I have:

`traverse`: Recursively walk through a directory, executing a command for
each file and subdirectory found. That command is usually a handler shell
function in your program.    
`traverse` is a fully cross-platform, robust replacement for `find` without
the snags of the latter. Any weird characters in file names (including
whitespace and even newlines) "just work" as expected, provided `use safe`
is invoked or shell expansions are quoted.    
`traverse` has minimal functionality of its own (depth-first search and an
option for `xargs`-like saving up of command arguments), but since the
command name can be a shell function, any functionality of 'find' and
anything else can be programmed in the shell language. The `install.sh`
script that comes with modernish provides a good example of its use.

`countfiles`: Count the files in a directory using nothing but shell
functionality, so without external commands. (It's amazing how many pitfalls
this has, so a library function is needed to do it robustly.)

### use sys/user ###
Features for obtaining information about the user accounts on the system.

Bash has the read-only variable $UID, as well as $USER which is not
read-only. They represent the ID and login name of the current user. The
`sys/user/id` module gives them to other shells too, plus makes both of them
read-only. If given the `-f` option (`use sys/user/id -f`), the module
overrides any existing values of these variables if they aren't read-only.

The `sys/user/loginshell` module provides for obtaining the current user's
login shell. It detects the current operating system's method for obtaining
this and sets the appropriate function.

### use sys/text ###
Functions for working with textfiles. So far I have:

`readf`: read a complete text file into a variable, stripping only the last
linefeed character.

`kitten` and `nettik`: `cat` and `tac` without launching any external process,
so it's faster for small text files.

### use opts/long ###
Adds a `--long` option to the getopts built-in for parsing GNU-style long
options. (Does not currently work in *ash* derivatives because `getopts`
has a function-local state in those shells. The only way out is to
re-implement `getopts` completely in shell code instead of building on
the built-in. This is on the TODO list.)

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
tests. The all-caps IDs below are all usable with the `thisshellhas`
function. This makes it easy for a cross-platform modernish script to write
optimizations taking advantage of certain non-standard shell features,
falling back to a standard method on shells without these features. On the
other hand, if universal compatibility is not a concern for your script, it
is just as easy to require certain features and exit with an error message
if they are not present, or to refuse shells with certain known bugs.

Most feature/quirk/bug tests have their own little test script in the
`libexec/modernish/cap` directory. These tests are executed on demand, the
first time the capability or bug in question is queried using
`thisshellhas`. **An ID in *`ITALICS`* denotes an ID for a "builtin" test,
which is always tested for at startup and doesn't have its own test script
file.**

### Capabilities ###

Non-standard shell capabilities currently tested for are:

* `LEPIPEMAIN`: execute last element of a pipe in the main shell, so that
  things like *somecommand* `| read` *somevariable* work. (zsh, AT&T ksh,
  bash 4.2+)
* *`RANDOM`*: the `$RANDOM` pseudorandom generator.
* *`LINENO`*: the `$LINENO` variable contains the current shell script line
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

### Quirks ###

Shell quirks currently tested for are:

* *`QRK_IFSFINAL`*: in field splitting, a final non-whitespace IFS delimiter
  character is counted as an empty field (yash \< 2.42, zsh, pdksh). This is a QRK
  (quirk), not a BUG, because POSIX is ambiguous on this.
* `QRK_32BIT`: mksh: the shell only has 32-bit arithmetics. Since every modern
  system these days supports 64-bit long integers even on 32-bit kernels, we
  can now count this as a quirk.
* `QRK_ARITHWHSP`: In [yash](https://osdn.jp/ticket/browse.php?group_id=3863&tid=36002)
  and FreeBSD /bin/sh, trailing whitespace from variables is not trimmed in arithmetic
  expansion, causing the shell to exit with an 'invalid number' error. POSIX is silent
  on the issue. The modernish `isint` function (to determine if a string is a valid
  integer number in shell syntax) is `QRK_ARITHWHSP` compatible, tolerating only
  leading whitespace.
* `QRK_EVALNOOPT`: `eval` does not parse options, not even `--`, which makes it
  incompatible with other shells: on the one hand, (d)ash does not accept   
  `eval -- "$command"` whereas on other shells this is necessary if the command
  starts with a `-`, or the command would be interpreted as an option to `eval`.
  A simple workaround is to prefix arbitary commands with a space.
  [Both situations are POSIX compliant](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_19_16),
  but since they are incompatible without a workaround,the minority situation
  is labeled here as a QuiRK.
* `QRK_LOCALSET`: On a shell with LOCAL, local variables are immediately set
  upon being declared. (zsh)
* `QRK_LOCALUNS`: On a shell with LOCAL, local variables lose their local
  status when unset. (yash, pdksh/mksh -- note: this is actually a behaviour
  of `typeset`, to which `local` is aliased on these shells)
* `QRK_LOCALINH`: On a shell with LOCAL, local variables, when declared
  without assigning a value, inherit the state of their global namesake, if
  any. (dash, FreeBSD sh)


### Bugs ###

Non-fatal shell bugs currently tested for are:

* `BUG_ALSUBSH`: Aliases defined within subshells leak upwards to the main shell.
  (Bug found in older versions of ksh93.)
* `BUG_APPENDC`: When `set -C` (`noclobber`) is active, "appending" to a nonexistent
  file with `>>` throws an error rather than creating the file. (zsh \< 5.1)
  This is a bug making `use safe` less convenient to work with, as this sets
  the `-C` (`-o noclobber`) option to reduce accidental overwriting of files.
  The `safe` module requies an explicit override to tolerate this bug.
* `BUG_ARITHTYPE`: In zsh, arithmetic assignments (using `let`, `$(( ))`,
  etc.) on unset variables assign a numerical/arithmetic type to a variable,
  causing subsequent normal variable assignments to be interpreted as
  arithmetic expressions and fail if they are not valid as such.
* `BUG_BRACQUOT`: shell quoting within bracket patterns has no effect (zsh < 5.3;
  ksh93) This bug means the `-` retains it special meaning of 'character
  range', and an initial `!` (and, on some shells, `^`) retains the meaning of
  negation, even in quoted strings within bracket patterns, including quoted
  variables.
* `BUG_CASESTAT`: The 'case' conditional construct prematurely clobbers the
  exit status `$?`. (found in zsh \< 5.3, Busybox ash \<= 1.25.0, dash \<
  0.5.9.1)
* `BUG_CMDOPTEXP`: the `command` builtin does not recognise options if they
  result from expansions. For instance, you cannot conditionally store `-p`
  in a variable like `defaultpath` and then do `command $defaultpath
  someCommand`. (found in zsh \< 5.3)
* `BUG_CMDPV`: `command -pv` does not find builtins. ({pd,m}ksh, zsh)
* `BUG_CMDSPCIAL`: zsh; mksh < R50e: 'command' does not turn off the 'special
  built-in' characteristics of special built-ins, such as exit shell on error.
* `BUG_CMDVRESV`: 'command -v' does not find reserved words such as "if".
  (pdksh, mksh). This necessitates a workaround version of thisshellhas().
* *`BUG_CNONASCII`*: the modernish functions `toupper` and `tolower` cannot
  **c**onvert non-ASCII letters to upper or lower case -- e.g. accented Latin
  letters, Greek, cyrillic. (Note: modernish falls back to the external
  `tr`, `awk`, `gawk` or GNU `sed` command if the shell can't convert non-ASCII
  (or any) characters, so this bug is only detected if none of these external
  commands can convert them. But if the shell can, then this bug is not
  detected even if the external commands cannot. The thing to take away from
  all this is that *the result of `thisshellhas BUG_CNONASCII` **only** applies
  to the modernish `toupper` and `tolower` functions* and not to your shell or
  any external command in particular.)
* `BUG_CSCMTQUOT`: unbalanced single and double quotes and backticks in comments
  within command substitutions cause obscure and hard-to-trace syntax errors
  later on in the script. (ksh88; pdksh, incl. {Open,Net}BSD ksh; bash 2.05b)
* `BUG_EMPTYBRE` is a `case` pattern matching bug in zsh < 5.0.8: empty
  bracket expressions eat subsequent shell grammar, producing unexpected
  results. This is particularly bad if you want to pass a bracket
  expression using a variable or parameter, and that variable or parameter
  could be empty. This means the grammar parsing depends on the contents
  of the variable!
* `BUG_FNREDIR`: I/O redirections on function definition commands are not
  remembered or honoured when the function is executed. (zsh4)
* `BUG_FNSUBSH`: Function definitions within subshells (including command
  substitutions) are ignored if a function by the same name exists in the
  main shell, so the wrong function is executed. `unset -f` is also silently
  ignored. ksh93 (all current versions as of June 2015) has this bug.
* *`BUG_HASHVAR`*: On zsh, `$#var` means the length of `$var` - other shells and
  POSIX require braces, as in `${#var}`. This causes interesting bugs when
  combining `$#`, being the number of positional parameters, with other
  strings. For example, in arithmetics: `$(($#-1))`, instead of the number of
  positional parameters minus one, is interpreted as `${#-}` concatenated with
  `1`. So, for zsh compatibility, always use `${#}` instead of `$#` unless it's
  stand-alone or followed by a space.
* *`BUG_IFSISSET`*: AT&T ksh93 (recent versions): `${IFS+s}` always yields 's'
  even if IFS is unset. This applies to IFS only.
* *`BUG_IFSWHSPE`*: Field splitting bug with IFS whitespace: an initial empty
  whitespace-separated field appears at the end of the expansion result
  instead of the start if IFS contains both whitespace and non-whitespace
  characters. (Found in AT&T ksh93 Version M 1993-12-28 p)
* *`BUG_KSHSUBVAR`*: ksh93: output redirection within a command substitution
  falsely resets the special `${.sh.subshell}` variable to zero. Since ksh93
  does subshells without forking, `${.sh.subshell}` is the ONLY way on ksh93
  to determine whether we're in a subshell or not. This bug affects the
  `insubshell` function which is essential for `die` and the trap stack.
  Workaround: save `${.sh.subshell}` within the command substitution but
  before doing output redirection, and restore it directly afterwards
  (amazingly, it's not a read-only variable). This bug is only detected
  on (recent versions of) AT&T ksh93 and never on other shells.
* *`BUG_LNNOEVAL`*: The shell has LINENO, but $LINENO is always expanded to 0
  when used in 'eval' or when expanding an alias. (pdksh variants, including
  mksh and oksh)
* *`BUG_MULTIBYTE`*: We're in a UTF-8 locale but the shell does not have
  multi-byte/variable-length character support. (Non-UTF-8 variable-length
  locales are not yet supported.) Dash is a recent shell with this bug.
* `BUG_NOCHCLASS`: POSIX-mandated character `[:`classes`:]` within bracket
  `[`expressions`]` are not supported in glob patterns. (pdksh, mksh, and
  family)
* `BUG_NOUNSETRO`: Cannot freeze variables as readonly in an unset state.
  This bug in zsh \< 5.0.8 makes the `readonly` command set them to the
  empty string instead.
* *`BUG_PARONEARG`*: When `IFS` is empty on bash 3.x and 4.x (i.e. field splitting
  is off), `${1+"$@"}` (the `BUG_UPP` workaround for `"$@"`) is counted as a
  single argument instead of each positional parameter as separate
  arguments. This is unlike every other shell and contrary to the standard
  as the working of `"$@"` is unrelated to field splitting.
  This bug renders the most convenient workaround for `BUG_UPP` ineffective on
  bash under `use safe` settings which include `set -o nounset` and empty
  `IFS`. :( Not that any version of bash has BUG_UPP, but cross-platform
  compatibility is hindered by this.
* `BUG_PSUBBKSL`: A backslash-escaped character within a quoted parameter
  substitution is not unescaped. (bash 2 & 3, standard dash, Busybox ash)
* `BUG_PSUBPAREN`: Parameter substitutions where the word to substitute contains
  parentheses wrongly cause a "bad substitution" error. (pdksh)
* *`BUG_READTWHSP`*: `read` does not trim trailing IFS whitespace if there
  is more than one field. (dash)
* `BUG_SELECTEOF`: in a shell-native 'select' loop, the REPLY variable
  is not cleared if the user presses Ctrl-D to exit the loop. (zsh)
* `BUG_SELECTRPL`: in a shell-native 'select' loop, input that is not a menu
  item is not stored in the REPLY variable as it should be. (mksh R50 2014)
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
* `BUG_UNSETFAIL`: the `unset` command sets a non-zero (fail) exit status
  if the variable to unset was either not set (some pdksh versions), or
  never set before (AT&T ksh 1993-12-28). This bug can affect the exit
  status of functions and dot scripts if 'unset' is the last command.
* *`BUG_UPP`*: Cannot access an empty set of positional parameters (i.e. empty
  `"$@"` or `"$*"`) if `set -u` (`-o nounset`) is active. If that option is
  set, NetBSD /bin/sh and older versions of ksh93 and pdksh error out, even
  if that access is implicit in a `for` loop (as in `for var do stuff; done`).
  This is a bug making `use safe` less convenient to work with, as this sets
  the `-u` (`-o nounset`) option to catch typos in variable names.
  The `safe` module requies an explicit override to tolerate this bug.
  Many workarounds are also necessary in the main library code (search the
  code for `BUG_UPP` to find them).
  The following workarounds are the most convenient. However, note that these
  are incompatible with `BUG_PARONEARG` in bash!
    * Instead of `"$@"`, use: `${1+"$@"}`
    * Instead of `"$*"`, use: `${1+"$*"}`
    * Instead of `for var do`, use: `for var in ${1+"$@"}; do`

---

`EOF`
