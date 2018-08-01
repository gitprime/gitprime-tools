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
# shellcheck source=../../library/common.sh
source "${GITPRIME_TOOLS_HOME}/library/common.sh"
# shellcheck source=../../library/cli.sh
source "${GITPRIME_TOOLS_HOME}/library/cli.sh"

declare -a HOOK_NAMES

HOOK_NAMES[0]="applypatch-msg"
HOOK_NAMES[1]="update"
HOOK_NAMES[2]="post-update"
HOOK_NAMES[3]="pre-applypatch"
HOOK_NAMES[4]="pre-push"
HOOK_NAMES[5]="pre-receive"
HOOK_NAMES[6]="commit-msg"
HOOK_NAMES[7]="pre-commit"
HOOK_NAMES[8]="prepare-commit-msg"
HOOK_NAMES[9]="pre-rebase"

# The required show_help function
function show_help() {
  log.info "The remove-git-hooks command will remove the GitPrime Tool Hooks From"
  log.info "the git repository specified.  If none is specified, it assumes that"
  log.info "the current directory is a git repository."

  log.info

  show_argument_info
}

function add_arguments() {
  add_cli_argument "help" "h" ${GPT_ARG_TYPE_FLAG} 0 "Shows the help screen"
  add_cli_argument "repo-path" "r" ${GPT_ARG_TYPE_VALUE} 0 "The path to the repository you want to remove hooks from"
}

# The required execute_gpt_command function
function execute_gpt_command() {
    REPO_PATH=$(get_argument_value "repo-path")

    log "Initial repo path"

    if [[ -z $REPO_PATH ]];
    then
        REPO_PATH=$(pwd)
    fi

    log "Beginning removal of GitPrime hooks system from repository located at ${REPO_PATH}"
}

function destroy() {
  # Nothing really to do here.
  log "Completed Removal of Git Hooks"
}
