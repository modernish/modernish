The `cap` directory contains all the external modernish shell
capability/bug/quirk tests, that is, those that aren't built in to the
initialisation routines in `bin/modernish`.

Each test file is a little dot script that is sourced by `thisshellhas` the
first time the corresponding capability is queried, if ever. The file name
must be its modernish capability ID (consisting only of ASCII capital
letters, digits and the underscore) plus the extension `.t`.

The dot script must return with one of the following three exit statuses:
* 0: The capability, bug or quirk in question was found on this shell.
* 1: The same was not found.
* 2: A fatal error occurred during testing. (Program execution will be aborted.)

These dot scripts may generally use basic modernish functionality, as most
of them are not sourced before modernish has been completely initialised.
They should do this sparingly, however; execution speed is of the utmost
importance. A test script should never `use` a modernish module.

Each test script should not assume anything about the environment going in,
and when returning leave the environment exactly as it found it. That is, no
test script should ever assume any particular state of IFS (field
splitting), globbing, or any other shell option or variable. If any of these
need to be changed, their state must be restored before exiting the test.
The modernish stack (`push` and `pop` functions) is convenient here, as it
supports both variables and short-form shell options.

As an exception to the above, the internal `_Msh_test` variable may be
freely used for testing purposes and does not need to be restored or unset.
