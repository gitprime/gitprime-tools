Scripts in this folder will be applied as hooks during the applypatch-msg hook.

    <order number>-<short-name>.<ext>
    
Some examples:

    10-check-jira-ticket.sh
    20-do-some-linting
    30-do-something-else

In the case of the files, they will be executed in the ascending order of their order number.
