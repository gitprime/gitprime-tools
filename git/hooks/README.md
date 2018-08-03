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

GitPrime Tools currently supports the following hook types:

* applypatch-msg
* commit-msg
* fsmonitor-watchman
* post-update
* pre-applypatch
* pre-commit
* prepare-commit-msg
* pre-push
* pre-rebase
* pre-receive
* update

# Usage
Enabling the hooks is easy.  You simply need to execute this command inside any git repository you want to
use the hooks with:

```gpt install-git-hooks```

Once the hooks are enabled, git actions inside that repository will use the GitPrime Tools hook delegator
to perform the following actions:

1. Run any hooks included as part of GitPrime Tools for the specific hook type. 
2. Run any hooks located in the .gpt/hooks directory of your repository.  See 
[Adding Your Own Hooks](#Adding Your Own Hooks) for more information on adding
these to your project.

# Adding Your Own Hooks
Adding hooks to your project's repository is incredibly easy.

1. Create a new directory, at the root of your project named `.gpt`.
2. Inside this directory, you create a sub-directory named `hooks`.
3. For each hook type, create a directory of that name to hold any hooks you want executed.

For example:

* `.gpt/hooks/commit-msg` would contain hooks the be executed at the "commit-msg" part of the Git lifecycle.
* `.gpt/hooks/pre-rebase` would contain hooks that will be executed during the "pre-rebase' phase. 

Hooks inside each directory run in order of their name.  It is recommended that all hooks be named
in a pattern matching:

```<numeric precedence order>-<name>```

All custom hooks are passed the same command line arguments that are regularly passed to Git
hooks.

For example, the following hooks would run in the order they are listed:

* 10-lint-my-files.sh
* 20-run-my-unit-tests.sh
* 30-validate-my-commit-message.sh

# Included Hooks
We believe that all developer commits to a repository should have a ticket number associated with it.
However, this does place some burden on the developer to remember to place it in the commit message
when they are working.

To alleviate that burden, we have adopted a process of using Git branches and the GitPrime Tools to
make this process simpler.  To that end, included in the GitPrime Tools are hooks that help enforce
a style of commit message that we prefer.

The process begins with the naming of work branches.  When a developer creates a branch, they are
encouraged to use the format of:

```<Ticket Number>/short_description_of_work```

For example, for ticket GP-0001:

* GP-0001/adding_gpt_hooks

If this naming convention is used, the included hooks will automatically find the ticket number
during the commit-msg phase of the Git lifecycle and reformat the given commit message into the following
format:

```
<Ticket Number>: <Commit Title>

<Commit Message Body>

<URL to Ticket>
```

Using the branch from the example above, the system would work as follows:

1. The developer creates the branch
2. The developer makes changes to the project
3. The developer stages those changes
4. The developer commits those changes using the message:

```
Enable GitPrime Tools Hooks
  
Added the .gpt directory and added a pre-rebase commit to better manage rebases.
```

The message is reformatted into the following format:

```
GP-0001: Enable GitPrime Tools Hooks
  
Added the .gpt directory and added a pre-rebase commit to better manage rebases.
  
https://jira.mydomain.com/browse/GP-0001
```

Addtionally, developers have the option to override this automatic ticket number by putting the ticket
number in the commit message themselves.  For example:

```git commit -m "GP-0002: My commit message```

Would override the ticket in the branch with "GP-0002" and reformat the message to be:

```
GP-0002: My commit message
  
https://jira.mydomain.com/browse/GP-0002
```
