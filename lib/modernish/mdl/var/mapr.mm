#! /module/for/moderni/sh

# var/mapr was renamed to sys/cmd/mapr.
# Redirect for compatibility. This will go away in future.

# Hack: Only put warning if this module is not being loaded recursively ('use var').
# See _Msh_doUse() in bin/modernish.
if not str eq "$1" "${_Msh_use_F-}"; then
	putln "${CCt}Warning: the var/mapr module was renamed to sys/cmd/mapr." \
		"${CCt}Please update the respective 'use' command in your script." \
		"${CCt}This compatibility redirect will go away in a future version."
fi

use sys/cmd/mapr
