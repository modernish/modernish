# modernish: design notes #

## Table of contents ##

* [Introduction](#user-content-introduction)
* [General design principles](#user-content-general-design-principles)
* [Practical design guidelines](#user-content-practical-design-guidelines)
    * [Directory structure](#user-content-directory-structure)
    * [Coding style](#user-content-coding-style)
    * [Robustness](#user-content-robustness)
    * [Security hardening](#user-content-security-hardening)
    * [Dealing with shell bugs](#user-content-dealing-with-shell-bugs)
    * [Optimisation](#user-content-optimisation)
    * [Portability testing](#user-content-portability-testing)

## Introduction ##

The programming/scripting language that incorporates the most
frustrating combination of deficiencies and
[awesome power](https://confreaks.tv/videos/gogaruco2010-the-shell-hater-s-handbook)
is probably the [POSIX shell with accompanying utilities](http://shellhaters.org/),
which all exist in several variant implementations. Due to said awesome power,
the POSIX shell has more than proven its staying power as a scripting language
and people have used it to automate all sorts of system tasks and much more for
decades. But arcane grammar pitfalls, defective tutorials on the web, and
functionality deficits also make it one of the most disparaged languages.

Modernish aims to provide a standard library that allows for writing robust,
portable, readable, and powerful programs for POSIX-based shells and
utilities. It combines little-used shell settings and a modular library of
functions to effectively build a new and improved shell language dialect on
top of existing shells. With modernish, you'd *almost* think the shell has
become a modern programming language!

## General design principles ##

Modernish has been designed with following principles in mind, most of which
are departures from conventional shell scripting practice.

-   *The shell is an actual programming language.* That's how it was designed
    and advertised right from the early days of the Bourne shell.
    Unfortunately, few take it seriously as such. Countless obsolete and broken
    habits dating from the 1970s and 80s continue to proliferate today in
    low-quality shell tutorials and courses around the web. Modernish treats
    the shell like a proper programming language by providing a standard
    library like any other language has. It also aims to encourage good,
    defensive programming practices by offering features that drastically
    improve the security and robustness of shell scripts.

    -   *The shell is still the shell.* Modernish does not try to turn the
        shell into a general-purpose programming language; instead, it aims to
        enable you to write better, safer, more compatible shell scripts. Its
        feature set is aimed at solving specific and commonly experienced
        deficits of the shell language, and not at adding things that are
        foreign to it, such as object orientation or functional programming.

-   *Safety by default.* The shell's default settings are designed for
    interactive command line use, and are not safe for scripts. Painstaing
    and error-prone quoting of nearly every variable expansion and command
    substitution is needed to cope with globally enabled field splitting and
    pathname expansion (globbing), and even then, pitfalls are where you
    would least expect them. Modernish introduces a new way of writing
    shell scripts called the safe mode:
    [safe mode](#user-content-use-safe):
    global split and glob is disabled, some other safer settings enabled,
    and modernish provides the functionality to make all this practical to
    use, such as safe and explicit split/glob operators on
    [loop constructs](#user-content-use-varloop) and
    [local variables/options blocks](#user-content-use-varlocal).
    Result: no more quoting hell!

    -   *No tolerance for chaos.* Modernish has been designed from the
        ground up with the idea that invalid or inconsistent input to
        commands is a sign of a fatal program bug that necessitates an
        immediate halt to avoid a potential catastrophe. Excessive or
        invalid arguments to commands are consisered fatal errors.
        Unexpected failure of system utilities is also considered fatal.
        Upon detecting such an inconsistent state, modernish calls
        [`die`](#user-content-reliable-emergency-halt)
        which reliably halts the entire program including all its subshells
        and subproceses, *even if the fatal error occurred within a subshell
        of your script*. Modernish also provides the
        [`harden`](#user-content-use-syscmdharden)
        function that programs can use to extend this principle to shell
        builtin and external utilities.

    -   *Safe command design.* The `[`/`test` command is designed to mislead
        you into thinking it's part of the shell grammar and is much easier to
        use in wrong and broken ways than it is to use it correctly. Its
        arcanely formulated options don't always test exactly for what the
        manual pages claim they test for. And due to empty removal, even the
        safe mode cannot eliminate quoting hell for it in the way it does
        for other commands. So modernish provides
        [replacements](#user-content-testing-numbers-strings-and-files)
        for `[` that are readable and hardened, provide enhanced functionality,
        actually do what they claim they do, and don't require quoting if the
        safe mode is used.

-   *Portability.* Most shell scripts, even general-purpose scripts for public
    use, are written for one particular shell: bash. Monoculture is a problem
    as it provides consistent attack vectors for hackers. If scripts are
    written in ways that are compatible with multiple shells and utility sets,
    they can be executed on multiple shells which makes it less practical to
    exploit any vulnerabilities. Modernish makes portable scripting practical.

    -   *If we name it, we can handle it.* Different shells have (a)
        different features and (b) different bugs and quirks. Technically,
        features, quirks and bugs are all the same thing. Modernish supports
        [particular features, quirks and bugs](#user-content-appendix-a)
        in current shell release versions, giving each an ID and a test in a
        [capability testing framework](#user-content-shell-capability-detection).
        This allows your script to easily check if `thisshellhas` a certain
        feature, quirk, or bug, and conditionally use code that depends on
        it or works around it. Another useful effect is that known shell
        bugs are publicly documented. They are reported to maintainers who
        can fix them, so (distant) future releases of modernish will stop
        supporting them as we drop support for ancient shell versions.

    -   *Complete functionality.* Essential and commonly used utilities such
        as `mktemp` or `readlink` are not standardised; different Unix-like
        systems provide different and incompatible versions, or none at all.
        Modernish provides its own
        [portable versions](#user-content-use-sysbase)
        of such utilities, with added functionality.

-   *Integration.* Essential functionality is fully integrated
    into the shell, instead of depending on external utilities whose results
    are difficult to use correctly. The current shell environment (your
    variables and shell functions) should be accessible and robust processing
    should be the default. Examples of this principle in action include the
    [`find` loop](#user-content-the-find-loop), the
    [`mapr`](#user-content-use-varmapr) utility, and automatic cleanup in
    modernish [`mktemp`](#user-content-use-sysbasemktemp).

    -   *Modularity.* The core modernish library is quite small. Most of the
        functionality is offered in the form of [modules](#user-content-modules).

    -   *Cooperation.* There needs to be a way for different modules (and
        any other script components) to work together without overwriting
        each other's settings. To that end, variables, shell options and
        traps can be [stacked](#user-content-the-stack).

---------------------------------

## Practical design guidelines ##

[ This section is not complete, and probably never will be. ]

See also `CODINGSTYLE` for notes concerning scripts that use modernish.

Design notes for modernish itself:

### Directory structure ###

- `bin`: the core modernish library lives here
- `lib`: base directory for all other code
- `lib/_install`: installation helper scripts (won't be installed)
- `lib/modernish`: all other modernish functionality
- `lib/modernish/aux`: core helper scripts
- `lib/modernish/aux/`*subdirs*: module helper scripts in corresponding subdirs
- `lib/modernish/cap`: shell capability test scripts (features, quirks, bugs)
- `lib/modernish/mdl`: modernish modules
- `lib/modernish/mdl/sys`: portable system utilities and enhancements
- `lib/modernish/mdl/sys/`*subdirs*: further subdivision (see README.md)
- `lib/modernish/mdl/var`: various enhancements for the shell language
- `lib/modernish/mdl/var/`*subdirs*: further subdivision (see README.md)
- `share/doc/modernish`: base directory for documentation
- `share/doc/modernish/examples`: example modernish scripts

### Coding style ###

- Indent with a single tab. Tabs are assumed to be 8 spaces wide.
  (This gives automatic compatibility with <<-EOF here-documents.)
- Prefer "if command1; then command2; fi"  over "command1 && command2"
  (unless you specifically want the exit status of command2).
  This avoids pitfalls with an unexpected non-zero exit status.

### Robustness ###

All modernish library functions must work regardless of:

- any currently set or unset POSIX shell options, except -e/errexit
- the state of IFS field splitting
- the current umask (even if it's 777)
- the value of PATH (even if /dev/null)
  (this means even regular builtins need the PATH defined, as POSIX
   specifies builtins are subject to a PATH search, and 'yash -o posix'
   actually does this)
- spaces, newlines, or weird characters in arguments or file names
- shell bugs and quirks detected and supported by modernish

Defensive programming is the mantra.

### Security hardening ###

- If any inconsistent program state is detected, modernish must die(),
  invoking the reliable emergency halt that kills the entire program
  including all associated processes, instead of simply exit. This will often
  keep buggy scripts from wreaking havoc.

- Always test for the correct arguments and die() if an incorrect number
  of arguments is given. This catches any unexpected field splitting and
  globbing (unquoted variables expanding into multiple arguments) which
  strongly indicates that the program is in an insonsistent state.

- Always validate or sanitise all data before use; die() on invalid data.
  This prevents injection vulnerabilities and buggy behaviour.

### Dealing with shell bugs ###

- In general, you should implement workarounds for known/supported shell
  bugs conditionally, so they only run on shells with the bug, like so:    
  `if thisshellhas BUG_FOOBAR; then` *code with workaround*; `else` *regular code*; `fi`    
  This is because workaround versions could trigger other bugs in other
  shells that you're not accounting for. However, if the workaround is (a)
  trivial and (b) extremely unlikely to cause problems on any shell, then
  implement it unconditionally like so:    
  *some workaround here*`	# BUG_FOOBAR compat`
  If you're not sure, err on the side of implementing a conditional
  workaround.    
  &nbsp; &nbsp; In any case, make sure the modernish ID of the bug you're working
  around is identified either as an argument to 'thisshellhas' or in a
  comment. This not only allows people reading the code to look up the bug
  and understand what's going on, but also makes it easy to remove the
  workarounds when modernish stops supporting a certain shell bug. (The
  above is good advice for programs using modernish as well!)

- All supported/detected shell bugs and quirks should have a corresponding
  test in the regression test suite, that tests the bug more extensively,
  as well as its documented workaround(s), and verifies that the
  capability detection framework detects the bug correctly. Use the
  'mustHave' and 'mustNotHave' helper functions. See existing regression
  tests using them for examples.

- When modernish stops supporting a certain shell bug (e.g. because all
  the shells that have the bug are obsolete), shells with that bug should
  be blocked with some fatal bug test in `aux/fatal.sh`, if they aren't already.
  In any case, the corresponding regression test should remain in the
  regression test suite, with the xfail turned into a FAIL.

### Optimisation ###

Optimise for speed, even if this causes repetitive code.
Avoid launching subshells like the plague unless there is no alternative
(command substitution, piping into loops, `( )`, all launch subshells).

### Portability testing ###

Test everything on `yash -o posix`. [yash](http://yash.osdn.jp/)
has the strictest POSIX mode and anything that passes that test is likely
to be compatible.
