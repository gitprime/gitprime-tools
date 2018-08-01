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

declare -aG HOOK_NAMES

GPT_HOOK_NAMES[0]="applypatch-msg"
GPT_HOOK_NAMES[1]="commit-msg"
GPT_HOOK_NAMES[2]="fsmonitor-watchman"
GPT_HOOK_NAMES[3]="post-update"
GPT_HOOK_NAMES[4]="pre-applypatch"
GPT_HOOK_NAMES[5]="pre-commit"
GPT_HOOK_NAMES[6]="prepare-commit-msg"
GPT_HOOK_NAMES[7]="pre-push"
GPT_HOOK_NAMES[8]="pre-rebase"
GPT_HOOK_NAMES[9]="pre-receive"
GPT_HOOK_NAMES[10]="update"

# The required show_help function
function show_help() {
  log.info "The remove-git-hooks command will remove the GitPrime Tool Hooks From"
  log.info "the git repository specified.  If none is specified, it assumes that"
  log.info "the current directory is a git repository."

  log.info

  show_argument_info
}

function add_arguments() {
  add_cli_argument "repo-path" "r" ${GPT_ARG_TYPE_VALUE} 0 "The path to the repository you want to remove hooks from"
}

# The required execute_gpt_command function
function execute_gpt_command() {
  REPO_PATH=$(get_argument_value "repo-path")

  if [[ -z $REPO_PATH ]];
  then
      REPO_PATH=$(pwd)
  fi

  local git_dir="${REPO_PATH}/.git"
  local hooks_dir="${git_dir}/hooks"

  log "Beginning removal of GitPrime hooks system from repository located at ${REPO_PATH}"

  if [[ -d "${REPO_PATH}" ]]; then
    if [[ -d "${git_dir}" ]]; then
      log.info "Found a valid git repository at: ${REPO_PATH}"

      if [[ -d "${hooks_dir}" ]]; then
        for hook_name in "${GPT_HOOK_NAMES[@]}"; do
          log.info "    Removing hook: ${hook_name}"

          rm -f "${hooks_dir}/${hook_name}"
        done
      else
        log.info "    There is no hooks directory in this repository.  Finishing up."
      fi
    else
      log.error "The directory specified is does not seem to be a git repository:: ${REPO_PATH}"

      return 1
    fi
  else
    log.error "The repository path specified is not a directory: ${REPO_PATH}"

    return 1
  fi
}

function destroy() {
  # Nothing really to do here.
  log "Completed Removal of Git Hooks"
}
