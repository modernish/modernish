#! /shell/bug/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# BUG_ZSHNAMES: A series of lowerase names, normally okay for script use as per
# POSIX convention, is reserved for special use. Unsetting these names is
# impossible in most cases, and changing them may corrupt important shell or
# system settings. This may conflict with POSIX sh scripts.
#
# This bug is detected on zsh when it was not initially invoked in emulation
# mode, and emulation mode was enabled using 'emulate sh' post invocation
# instead (which does not disable these conflicting parameters).
#
# The list of variable names affected is: aliases argv builtins cdpath
# commands dirstack dis_aliases dis_builtins dis_functions
# dis_functions_source dis_galiases dis_patchars dis_reswords dis_saliases
# fignore fpath funcfiletrace funcsourcetrace funcstack functions
# functions_source functrace galiases histchars history historywords jobdirs
# jobstates jobtexts keymaps mailpath manpath module_path modules nameddirs
# options parameters patchars path pipestatus prompt psvar reswords saliases
# signals status termcap terminfo userdirs usergroups watch widgets
# zsh_eval_context zsh_scheduled_events
#
# See also BUG_ZSHNAMES2.

isset path || return 1

(
	PATH=/dev/null:/dev/null
	path=_Msh_path_modifies_PATH
	case $PATH in
	( _Msh_path_modifies_PATH:/dev/null )
		;;
	( * )	\exit 1 ;;
	esac
) 2>/dev/null || return 1
