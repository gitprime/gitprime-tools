#!/usr/bin/env bash
#
# This code is licensed.  For details, please see the license file at
# https://github.com/gitprime/gitprime-tools/blob/master/LICENSE.md
#

# The purpose of this command is simple:  Install the git hooks into
# the given git repository.  If none is specified, we'll check the
# local directory for a valid .git directory/database and assume
# this is where the user wants them.

# We need some includes
source "${GITPRIME_TOOLS_HOME}/library/common.sh"
source "${GITPRIME_TOOLS_HOME}/library/cli.sh"

# The required show_help function
function show_help()
{
    log.info "Showing help here..."
}


# The required execute_gpt_command function
function execute_gpt_command()
{
    local command_name=$1

    shift

    local arguments=$@

    add_cli_argument "help" "h" ${GPT_ARG_TYPE_FLAG} 0 "Shows the help screen"
    add_cli_argument "repo-path" "r" ${GPT_ARG_TYPE_VALUE} 0 "The path to the git repository you want to add hooks to"

    parse_cli_arguments ${arguments}
}