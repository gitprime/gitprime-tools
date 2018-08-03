# Overview
GitPrime Tools were originally created to provide an extensible mechanism for using Git hooks.  This
part of the GitPrime Tools packages is very extensible and can be used to extend and enforce developer
workflows when using Git.

However, Git does not provide a mechanism to persist those as part of your git repository.  They reside
inside the .git folder, and are not pushed to remote repositories as part of the normal commit
process.

This limitation means that every time a developer freshly clones a project, they must re-establish their
commit hooks.

GitPrime Tools provides a system for working around this by providing:

* A "hook delegator" that executes appropriate hooks for every hook in the Git lifecycle.
* A mechanism to quickly install hooks into a freshly cloned project.
* A system that allows developers to add their own hooks to the system
* A way to allow those hooks to be maintained per-project.
* A system that allows custom hooks to be stored and maintained in the project as part of the regular
development lifecycle and commit/push process. 

# Usage


# Included Hooks
We believe that all developer commits to a repository should have a ticket number associated with it.
However, this does place some burden on the developer to remember to place it in the commit message
when they are working.

# Adding Your Own Hooks
