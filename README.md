# GitPrime Tools
Tools for Git users and GitPrime Customers

## Overview
The GitPrime Tools (GPT) are command-line tools, based on Bash, indented to give developers extra tools they can use to
better perform their jobs.

Build as an extensible "command executor", the tools can be extended easily to provide new functionality as
we find more things that we can help developers do better with CLI short-cuts.

Current features include:

* Git hook extensions to allow developers to embed hooks into their projects that are automatically executed.
* Bash-based scripting libraries that can be used in other scripting projects.
* Built-in update installation tools to keep the GPT up-to-date.

## Installation
Installation of the GitPrime Tools is very simple and straight forward.  To install them:

1. Download the latest release from: [https://github.com/gitprime/gitprime-tools/releases](https://github.com/gitprime/gitprime-tools/releases)
2. Decompress the downloaded artifact into a temporary directory.
3. In a terminal window, change to the directory where you decompressed the artifact.  For example
  
   ```cd /tmp/gitprime-tools-1.0.0```
  
4. Execute the installation script using:

   ```bin/install-tools.sh```
    
5. Exit your terminal window and open a new one so that the new settings and tools are properly activated.

The installer allows for a few options on installation:

* --directory: This option sets the directory where the GitPrime Tools will be installed on your system.
This defaults to `${HOME}/.gitprime-tools`
* --ticket-url:  This sets the URL of your ticket-tracking system.  This URL will be used by the ticket-enforcement
git hooks.  (See 'Commit Hooks' below.)  For example:
  * For JIRA:  https://jira.mydomain.com/browse will be converted to https://jira.mydomain.com/browse/<Ticket Number>
* --help:  Will show information about how to use the installer.
  
## Usage
Once the tools are properly installed and activated in your terminal, there are several commands you can 
execute.  To see the list of commands available to you, execute:

```gpt help```

Executing commands is as simple as:

```gpt <command> <options>```

For example, to update the GitPrime Tools, execute:

* Update GitPrime Tools to the latest version:
 
  ```gpt update```

* See a list of available updates:

  ```gpt update --list```

## Commit Hooks
GitPrime Tools were originally created to provide an extensible mechanism for using Git hooks.  This
part of the GitPrime Tools packages is very extensible and can be used to extend and enforce developer
workflows when using Git.

More information can be found at: [Commit Hooks](git/hooks/README.md)
