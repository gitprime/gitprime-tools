# GitPrime Developer Tool Commands

The concept here is that we support sub-commands that are executed from the main gitprime-tools.sh
and passed the current environment and data.

To write your own command, you simply need to implement a bash script that implements the
following two functions:

1. **show_help()**:  This should take no arguments.  It should, however, log out any help information
about the given command.

2. **execute_gpt_command()**:  This is where you should perform all your logic.  You will be passed all command
line arguments.  These can be parsed using the cli include.  This is expected to return a non-zero
exit code if there is a failure in the logic.
