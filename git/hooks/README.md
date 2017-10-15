In this folder you will find a directory for each available hook that git allows.  Inside each
folder you will find scripts that are executed for those commit hooks.  Scripts should be named
as follows:

    <order number>-<short-name>.<ext>
    
Some examples:

    10-check-jira-ticket.sh
    20-do-some-linting
    30-do-something-else

In the case of the files, they will be executed in the ascending order of their order number.
