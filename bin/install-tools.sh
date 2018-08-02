#!/usr/bin/env bash
#
# This code is licensed.  For details, please see the license file at
# https://github.com/gitprime/gitprime-tools/blob/master/LICENSE.md
#

# This script is intended to install the GitPrime tool set into
# a location specified.

# Some variables we need and will be setting

# The home directory for the tools
if [[ ! -z "${GITPRIME_TOOLS_HOME}" ]]; then
  GPT_HOME="${GITPRIME_TOOLS_HOME}"
else
  GPT_HOME="${HOME}/.gitprime-tools"
fi

# The base URL for tickets
if [[ ! -z "${GITPRIME_TOOLS_TICKET_URL}" ]]; then
  GPT_TICKET_URL="${GITPRIME_TOOLS_TICKET_URL}"
else
  GPT_TICKET_URL=0
fi

# A tmp directory to do some work in
TMP_DIRECTORY=0

# The directory we're running in so that we can source some stuff
CMD_BASE_DIR=$0

CMD_BASE_DIR=$(dirname "${CMD_BASE_DIR}")

if [[ "${CMD_BASE_DIR}" != "/"* ]]; then
  # We used a relative path, we'll add the current working directory
  CMD_BASE_DIR="$(pwd)/${CMD_BASE_DIR}"
fi

if [[ "${CMD_BASE_DIR}" == *"/bin" ]]; then
  CMD_BASE_DIR=$(dirname "${CMD_BASE_DIR}")
fi

# Import the common libraries.  This lets us use all our nifty code.  However, because they sometimes rely on
# the GITPRIME_TOOLS_HOME environment variable, we're going to cheat that a bit.
# shellcheck source=../../library/common.sh
GITPRIME_TOOLS_HOME="${CMD_BASE_DIR}" source "${CMD_BASE_DIR}/library/common.sh"
# shellcheck source=../../library/cli.sh
GITPRIME_TOOLS_HOME="${CMD_BASE_DIR}" source "${CMD_BASE_DIR}/library/cli.sh"

# The required show_help function
function show_help() {
  log.info "The install command will attempt to install GitPrime Tools."

  log.info

  show_argument_info
}

function add_arguments() {
  add_cli_argument "help" "h" ${GPT_ARG_TYPE_FLAG} 0 "Show the help information."
  add_cli_argument "home-directory" "d" ${GPT_ARG_TYPE_VALUE} 0 "The directory where you want your new GitPrime Tools installation."
  add_cli_argument "ticket-url" "t" ${GPT_ARG_TYPE_VALUE} 0 "The URL of your ticket server to include in commit messages."
}

add_arguments

parse_cli_arguments "$@"

if [[ ${#GPT_ARG_PARSER_ERRORS} -gt 0 ]]; then
  log.error "There were invalid command options: "

  for parser_error in "${GPT_ARG_PARSER_ERRORS[@]}"; do
    log.error "    * ${parser_error}"
  done

  show_help

  handle_exit 1
fi

# Ok, we parsed the CLI options, now we need to use them
HELP_TEST=$(get_argument_value "help")

if [[ ${HELP_TEST} == 1 ]]; then
  show_help

  handle_exit 0
fi

# If we got a home directory, we need to override the one we guessed at.
HOME_TEST=$(get_argument_value "home-directory")

if [[ "${HOME_TEST}" != "-1" ]] && [[ ! -z "${HOME_TEST}" ]]; then
  # Looks like we got one
  GPT_HOME="${HOME_TEST}"
fi

# If we got a ticket URL, we need to override the one we guessed at.
TICKET_URL_TEST=$(get_argument_value "ticket-url")

log "Ticket URL test: #${TICKET_URL_TEST}#"

if [[ "${TICKET_URL_TEST}" != "-1" ]] && [[ ! -z "${TICKET_URL_TEST}" ]]; then
  # Looks like we got one
  GPT_TICKET_URL="${TICKET_URL_TEST}"
fi

log "About to install the GitPrime Development tools to ${GPT_HOME}."

if [[ ${GPT_TICKET_URL} != 0 ]]; then
  if [[ "${GPT_TICKET_URL}" != *"/" ]]; then
    GPT_TICKET_URL="${GPT_TICKET_URL}/"
  fi

  log "Setting the base ticket URL to: ${GPT_TICKET_URL}"
fi

# Ok, we have enough data to continue, lets validate a few things.
TMP_BASE_DIR=$(dirname "${GPT_HOME}")

if [[ ! -w "${TMP_BASE_DIR}" ]]; then
  handle_exit 100 "No permission to create home directory at ${GPT_HOME}"
fi

if [[ -d "${GPT_HOME}" ]]; then
  log "Removing previous installation of tools from ${GPT_HOME}"

  rm -fr "${GPT_HOME}"

  react_to_exit_code $? "Unable to remove previous installation from ${GPT_HOME}"
fi

cp -R "${CMD_BASE_DIR}" "${GPT_HOME}"

react_to_exit_code $? "Unable to copy installation to ${GPT_HOME}"

export GITPRIME_TOOLS_HOME="${GPT_HOME}"

export GITPRIME_TOOLS_TICKET_URL="${GPT_TICKET_URL}"

update_environment_files "${GPT_HOME}" "${GPT_TICKET_URL}"

log "Installation completed."
log ""
log.warn "The tools have been successfully installed.  However, you will not be able to"
log.warn "use them until you have reloaded your shell environment.  It is suggested that"
log.warn "you logout and log back in."

handle_exit 0
