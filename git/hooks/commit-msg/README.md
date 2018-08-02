Scripts in this folder will be applied as hooks during the commit-msg hook.

    <order number>-<short-name>.<ext>
    
Some examples:

* 10-check-jira-ticket.sh
* 20-do-some-linting
* 30-do-something-else

In the case of the files, they will be executed in the ascending order of their order number.

We have included a single script here that will automatically format commit messages using the ticket number
from the current branch name, if it can find it.  For example:

Given this branch name:

    GP-5032/some_description
    
The code will pick up the ticket number:
 
 * GP-5032
 
The message will then be formatted to the following pattern:

    <Ticket Number>: Commit title
    
    Commit message
    
    <URL to Ticket>

For example:

    GP-5032: This is a commit
    
    I've done some work for the given ticket.
    
    https://jira.example.org/browse/GP-5032
